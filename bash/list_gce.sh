#!/bin/bash

INSTANCE_FILE="instance.csv"
DISK_FILE="disk.csv"

# CSVヘッダーを初期化
echo "project,name,zone,machineType,vCPU,MemoryGB,status,internalIP,OS" > "$INSTANCE_FILE"
echo "project,name,zone,sizeGb,type" > "$DISK_FILE"

get_instances() {
  local proj="$1"
  gcloud compute instances list --project "$proj" --format="json" \
  | jq -r --arg proj "$proj" '
    .[] | {
      name: .name,
      zone: (.zone | split("/")[-1]),
      machineType: (.machineType | split("/")[-1]),
      status: .status,
      internalIP: .networkInterfaces[0].networkIP,
      licenses: (.disks[0].licenses // [])
    }
    | .os = (
        .licenses[]
        | select(test("(ubuntu|debian|centos|rhel|windows|sles)-"))
        | split("/")[-1]
      )
    | "\($proj),\(.name),\(.zone),\(.machineType),\(.status),\(.internalIP),\(.os)"
  ' | while IFS=, read -r proj name zone machineType status ip os; do
      # CPU/memory を machineType から取得
      cpu=$(gcloud compute machine-types describe "$machineType" --project "$proj" --zone "$zone" --format="value(guestCpus)" 2>/dev/null)
      mem=$(gcloud compute machine-types describe "$machineType" --project "$proj" --zone "$zone" --format="value(memoryMb)" 2>/dev/null)
      mem_gb=$(awk "BEGIN { printf \"%.1f\", $mem/1024 }")
      echo "$proj,$name,$zone,$machineType,$cpu,$mem_gb,$status,$ip,$os"
  done
} >> "$INSTANCE_FILE"

get_disks() {
  gcloud compute disks list --project "$1" \
    --format="csv[no-heading](
      name,
      zone.basename(),
      sizeGb,
      type.basename()
    )" \
    | awk -v proj="$1" -F, '{
        print proj "," $1 "," $2 "," $3 "," $4
      }'
} >> "$DISK_FILE"

while read -r proj; do
  [ -z "$proj" ] && continue
  get_instances "$proj"
  get_disks "$proj"
done < project_id.conf
