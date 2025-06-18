#!/bin/bash
set -e

source "$(dirname "$0")/script-utils.sh"

kli_1() {
  if [ ! -f .venv_1/bin/kli ]; then
    python3.12 -m venv .venv_1
    .venv_1/bin/pip install keri==1.1.32
  fi

  .venv_1/bin/kli "$@"
}

suffix=$(random_name t)
delegator_1="delegator_1_$suffix"
delegator_2="delegator_2_$suffix"
delegate_1="delegate_1_$suffix"
delegate_2="delegate_2_$suffix"
delegate_3="delegate_3_$suffix"

kli_1 init --name "$delegator_1" --nopasscode
kli_1 init --name "$delegator_2" --nopasscode
kli init --name "$delegate_1" --nopasscode
kli init --name "$delegate_2" --nopasscode
kli init --name "$delegate_3" --nopasscode

delegator_witness_aid="BLskRTInXnMxWaGqcpSyMgo0nYbalW99cGZESrz3zapM"
delegator_witness_url="http://127.0.0.1:5643/oobi/$delegator_witness_aid/controller"
delegate_witness_aid="BBilc4-L3tFUnfM_wJr4S4OJanAv_VmF_dJNN6vkf2Ha"
delegate_witness_url="http://127.0.0.1:5642/oobi/$delegate_witness_aid/controller"
# delegator_witness_aid="BBilc4-L3tFUnfM_wJr4S4OJanAv_VmF_dJNN6vkf2Ha"
# delegator_witness_url="http://127.0.0.1:5642/oobi/$delegate_witness_aid/controller"

kli_1 oobi resolve --name "$delegator_1" --oobi "$delegator_witness_url"
kli_1 oobi resolve --name "$delegator_2" --oobi "$delegator_witness_url"
kli oobi resolve --name "$delegate_1" --oobi "$delegate_witness_url"
kli oobi resolve --name "$delegate_2" --oobi "$delegate_witness_url"
kli oobi resolve --name "$delegate_3" --oobi "$delegate_witness_url"

kli_1 incept --name "$delegator_1" --alias member --icount 1 --ncount 1 --isith 1 --nsith 1 --transferable --toad 1 --wit "$delegator_witness_aid"
kli_1 incept --name "$delegator_2" --alias member --icount 1 --ncount 1 --isith 1 --nsith 1 --transferable --toad 1 --wit "$delegator_witness_aid"
kli_1 ends add --name "$delegator_1" --alias member --eid "$delegator_witness_aid" --role mailbox
kli_1 ends add --name "$delegator_2" --alias member --eid "$delegator_witness_aid" --role mailbox

delegator_1_aid=$(kli_1 status --name "$delegator_1" --alias member | grep "Identifier: " | cut -d ' ' -f 2)
delegator_1_oobi=$(kli_1 oobi generate --name "$delegator_1" --alias member --role witness | tail -n 1)
delegator_2_aid=$(kli_1 status --name "$delegator_2" --alias member | grep "Identifier: " | cut -d ' ' -f 2)
delegator_2_oobi=$(kli_1 oobi generate --name "$delegator_2" --alias member --role witness | tail -n 1)

kli_1 oobi resolve --name "$delegator_1" --oobi "$delegator_2_oobi" --oobi-alias delegator_2
kli_1 oobi resolve --name "$delegator_2" --oobi "$delegator_1_oobi" --oobi-alias delegator_1

delegator_json=$(mktemp)
cat << EOF > "$delegator_json"
{
  "transferable": true,
  "wits": ["$delegator_witness_aid"],
  "aids": ["$delegator_1_aid", "$delegator_2_aid"],
  "toad": 1,
  "isith": "2",
  "nsith": "2"
}
EOF

kli_1 multisig incept --name "$delegator_1" --alias member --group delegator --file "$delegator_json" &
pid=$!
kli_1 multisig incept --name "$delegator_2" --alias member --group delegator --file "$delegator_json"
wait $pid

kli incept --name "$delegate_1" --alias member --icount 1 --ncount 1 --isith 1 --nsith 1 --transferable --toad 1 --wit "$delegate_witness_aid"
kli incept --name "$delegate_2" --alias member --icount 1 --ncount 1 --isith 1 --nsith 1 --transferable --toad 1 --wit "$delegate_witness_aid"
kli incept --name "$delegate_3" --alias member --icount 1 --ncount 1 --isith 1 --nsith 1 --transferable --toad 1 --wit "$delegate_witness_aid"
kli ends add --name "$delegate_1" --alias member --eid "$delegate_witness_aid" --role mailbox
kli ends add --name "$delegate_2" --alias member --eid "$delegate_witness_aid" --role mailbox
kli ends add --name "$delegate_3" --alias member --eid "$delegate_witness_aid" --role mailbox

delegate_1_oobi=$(kli oobi generate --name "$delegate_1" --alias member --role witness | tail -n 1)
delegate_2_oobi=$(kli oobi generate --name "$delegate_2" --alias member --role witness | tail -n 1)
delegate_3_oobi=$(kli oobi generate --name "$delegate_3" --alias member --role witness | tail -n 1)
delegate_1_aid=$(kli aid --name "$delegate_1" --alias member)
delegate_2_aid=$(kli aid --name "$delegate_2" --alias member)
delegate_3_aid=$(kli aid --name "$delegate_3" --alias member)
delegator_oobi=$(kli_1 oobi generate --name "$delegator_1" --alias delegator --role witness | tail -n 1)
delegator_aid=$(kli_1 status --name "$delegator_2" --alias delegator | grep "Identifier: " | cut -d ' ' -f 2)

kli oobi resolve --name "$delegate_1" --oobi-alias delegator --oobi "${delegator_oobi}"
kli oobi resolve --name "$delegate_1" --oobi-alias delegator_1 --oobi "${delegator_1_oobi}"
kli oobi resolve --name "$delegate_1" --oobi-alias delegator_2 --oobi "${delegator_2_oobi}"
kli oobi resolve --name "$delegate_1" --oobi-alias delegate_2 --oobi "${delegate_2_oobi}"
kli oobi resolve --name "$delegate_1" --oobi-alias delegate_3 --oobi "${delegate_3_oobi}"

kli oobi resolve --name "$delegate_2" --oobi-alias delegator --oobi "${delegator_oobi}"
kli oobi resolve --name "$delegate_2" --oobi-alias delegator_1 --oobi "${delegator_1_oobi}"
kli oobi resolve --name "$delegate_2" --oobi-alias delegator_2 --oobi "${delegator_2_oobi}"
kli oobi resolve --name "$delegate_2" --oobi-alias delegate_1 --oobi "${delegate_1_oobi}"
kli oobi resolve --name "$delegate_2" --oobi-alias delegate_3 --oobi "${delegate_3_oobi}"

kli oobi resolve --name "$delegate_3" --oobi-alias delegate_1 --oobi "${delegate_1_oobi}"
kli oobi resolve --name "$delegate_3" --oobi-alias delegate_2 --oobi "${delegate_2_oobi}"

kli_1 oobi resolve --name "$delegator_1" --oobi-alias delegate_1 --oobi "${delegate_1_oobi}"
kli_1 oobi resolve --name "$delegator_1" --oobi-alias delegate_2 --oobi "${delegate_2_oobi}"
kli_1 oobi resolve --name "$delegator_2" --oobi-alias delegate_1 --oobi "${delegate_1_oobi}"
kli_1 oobi resolve --name "$delegator_2" --oobi-alias delegate_2 --oobi "${delegate_2_oobi}"

delegate_json=$(mktemp)
cat << EOF > "$delegate_json"
{
    "transferable": true,
    "toad": 1,
    "wits": ["$delegate_witness_aid"],
    "aids": ["$delegate_1_aid", "$delegate_2_aid", "$delegate_3_aid"],
    "isith": "2",
    "nsith": "2",
    "delpre": "$delegator_aid"
}
EOF

# Delegate 1 initiates the delegated identifier
kli multisig incept --name "$delegate_1" --alias member --group delegate --file "$delegate_json" &
PID_LIST="$!"
kli multisig incept --name "$delegate_2" --alias member --group delegate --file "$delegate_json" &
PID_LIST+=" $!"
kli_1 delegate confirm --name "$delegator_1" --alias delegator --interact -Y &
PID_LIST+=" $!"
kli_1 delegate confirm --name "$delegator_2" --alias delegator --interact -Y &
PID_LIST+=" $!"

echo kli oobi resolve --name "$delegate_1" --oobi-alias delegator --oobi "${delegator_oobi}"
echo kli oobi resolve --name "$delegate_2" --oobi-alias delegator --oobi "${delegator_oobi}"
wait $PID_LIST
# kli oobi resolve --name "$delegate_1" --oobi-alias delegator --oobi "${delegator_oobi}"
# kli oobi resolve --name "$delegate_2" --oobi-alias delegator --oobi "${delegator_oobi}"
# wait $INCEPT_LIST

# kli status --name "$delegate_1" --alias delegate
# delegate_aid_from_1=$(kli aid --name "$delegate_1" --alias delegate)

# # Delegate 2 now catches up by joining the inception event
echo kli oobi resolve --name "$delegate_3" --oobi-alias delegator --oobi "${delegator_oobi}"
echo kli multisig join --name "$delegate_3" --auto --group delegate
echo kli status --name "$delegate_3" --alias delegate
# delegate_aid_from_3=$(kli aid --name "$delegate_3" --alias delegate)

# if [[ "$delegate_aid_from_1" != "$delegate_aid_from_3" ]]; then
#     echo "Delegate AIDs do not match"
#     exit 1
# fi
