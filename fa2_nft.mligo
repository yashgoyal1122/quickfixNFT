type token_id = nat
//answer_hash type definition
type answer_hash = bytes

type transfer_destination =
[@layout:comb]
{
  to_ : address;
  token_id : token_id;
  amount : nat;
}

type transfer =
[@layout:comb]
{
  from_ : address;
  txs : transfer_destination list;
}

type balance_of_request =
[@layout:comb]
{
  owner : address;
  token_id : token_id;
}

type balance_of_response =
[@layout:comb]
{
  request : balance_of_request;
  balance : nat;
}

type balance_of_param =
[@layout:comb]
{
  requests : balance_of_request list;
  callback : (balance_of_response list) contract;
}

type operator_param =
[@layout:comb]
{
  owner : address;
  operator : address;
  token_id: token_id;
}

type update_operator =
[@layout:comb]
  | Add_operator of operator_param
  | Remove_operator of operator_param
//storing answer hash in token metadata
type token_metadata =
[@layout:comb]
{
  token_id : token_id;
  token_info : (string, bytes) map;
  answer_hash : answer_hash;
}

type token_metadata_storage = (token_id, token_metadata) big_map

type token_metadata_param = 
[@layout:comb]
{
  token_ids : token_id list;
  handler : (token_metadata list) -> unit;
}
//changing minting parameters to take answer as string input
type mint_params =
[@layout:comb]
{
  link_to_metadata: bytes;
  owner: address;
  answer: string;
}
//definition for token_shop_entrypoint which expects the answer_hash
type buy_token_parameters = 
[@layout:comb]
{
    sent_answer_hash : answer_hash;
    recieved_answer_hash : answer_hash;
    token_id : token_id;
}

//defining parameters for GetAnswerHash entrypoint
type get_answer_parameters = {
  token_id: token_id;
  sent_answer_hash : answer_hash;
  contract_reference : (buy_token_parameters) contract;
}

type fa2_entry_points =
  | Transfer of transfer list
  | Balance_of of balance_of_param
  | Update_operators of update_operator list
  | Mint of mint_params
  | Burn of token_id
  | GetAnswerHash of get_answer_parameters

type contract_metadata = (string, bytes) big_map

type transfer_destination_descriptor =
[@layout:comb]
{
  to_ : address option;
  token_id : token_id;
  amount : nat;
}

type transfer_descriptor =
[@layout:comb]
{
  from_ : address option;
  txs : transfer_destination_descriptor list
}

type transfer_descriptor_param =
[@layout:comb]
{
  batch : transfer_descriptor list;
  operator : address;
}

let fa2_token_undefined = "FA2_TOKEN_UNDEFINED" 

let fa2_insufficient_balance = "FA2_INSUFFICIENT_BALANCE"

let fa2_tx_denied = "FA2_TX_DENIED"

let fa2_not_owner = "FA2_NOT_OWNER"

let fa2_not_operator = "FA2_NOT_OPERATOR"

let fa2_operators_not_supported = "FA2_OPERATORS_UNSUPPORTED"

let fa2_receiver_hook_failed = "FA2_RECEIVER_HOOK_FAILED"

let fa2_sender_hook_failed = "FA2_SENDER_HOOK_FAILED"

let fa2_receiver_hook_undefined = "FA2_RECEIVER_HOOK_UNDEFINED"

let fa2_sender_hook_undefined = "FA2_SENDER_HOOK_UNDEFINED"

type operator_transfer_policy =
  [@layout:comb]
  | No_transfer
  | Owner_transfer
  | Owner_or_operator_transfer

type owner_hook_policy =
  [@layout:comb]
  | Owner_no_hook
  | Optional_owner_hook
  | Required_owner_hook

type custom_permission_policy =
[@layout:comb]
{
  tag : string;
  config_api: address option;
}

type permissions_descriptor =
[@layout:comb]
{
  operator : operator_transfer_policy;
  receiver : owner_hook_policy;
  sender : owner_hook_policy;
  custom : custom_permission_policy option;
}

type operator_storage = ((address * (address * token_id)), unit) big_map

let update_operators (update, storage : update_operator * operator_storage)
    : operator_storage =
  match update with
  | Add_operator op -> 
    Big_map.update (op.owner, (op.operator, op.token_id)) (Some unit) storage
  | Remove_operator op -> 
    Big_map.remove (op.owner, (op.operator, op.token_id)) storage

let validate_update_operators_by_owner (update, updater : update_operator * address)
    : unit =
  let op = match update with
  | Add_operator op -> op
  | Remove_operator op -> op
  in
  if op.owner = updater then unit else failwith fa2_not_owner

let fa2_update_operators (updates, storage
    : (update_operator list) * operator_storage) : operator_storage =
  let updater = Tezos.sender in
  let process_update = (fun (ops, update : operator_storage * update_operator) ->
    let _u = validate_update_operators_by_owner (update, updater) in
    update_operators (update, ops)
  ) in
  List.fold process_update updates storage

type operator_validator = (address * address * token_id * operator_storage)-> unit

let make_operator_validator (tx_policy : operator_transfer_policy) : operator_validator =
  let can_owner_tx, can_operator_tx = match tx_policy with
  | No_transfer -> (failwith fa2_tx_denied : bool * bool)
  | Owner_transfer -> true, false
  | Owner_or_operator_transfer -> true, true
  in
  (fun (owner, operator, token_id, ops_storage 
      : address * address * token_id * operator_storage) ->
    if can_owner_tx && owner = operator
    then unit
    else if not can_operator_tx
    then failwith fa2_not_owner
    else if Big_map.mem  (owner, (operator, token_id)) ops_storage
    then unit 
    else failwith fa2_not_operator 
  )

let default_operator_validator : operator_validator =
  (fun (owner, operator, token_id, ops_storage 
      : address * address * token_id * operator_storage) ->
    if owner = operator
    then unit 
    else if Big_map.mem (owner, (operator, token_id)) ops_storage
    then unit 
    else failwith fa2_not_operator 
  )

let validate_operator (tx_policy, txs, ops_storage 
    : operator_transfer_policy * (transfer list) * operator_storage) : unit =
  let validator = make_operator_validator tx_policy in
  List.iter (fun (tx : transfer) -> 
    List.iter (fun (dst: transfer_destination) ->
      validator (tx.from_, Tezos.sender, dst.token_id ,ops_storage)
    ) tx.txs
  ) txs

type token_def =
[@layout:comb]
{
  from_ : nat;
  to_ : nat;
}

type nft_meta = (token_def, token_metadata) big_map

type token_storage = {
  token_defs : token_def set;
  next_token_id : token_id;
  metadata : nft_meta;
}

type ledger = (token_id, address) big_map
type reverse_ledger = (address, token_id list) big_map

type nft_token_storage = {
  ledger : ledger;
  operators : operator_storage;
  reverse_ledger: reverse_ledger;
  metadata: (string, bytes) big_map;
  token_metadata: token_metadata_storage;
  next_token_id: token_id;
  admin: address;
}

let get_balance (p, ledger : balance_of_param * ledger) : operation =
  let to_balance = fun (r : balance_of_request) ->
    let owner = Big_map.find_opt r.token_id ledger in
    match owner with
    | None -> (failwith fa2_token_undefined : balance_of_response)
    | Some o ->
      let bal = if o = r.owner then 1n else 0n in
      { request = r; balance = bal; }
  in
  let responses = List.map to_balance p.requests in
  Tezos.transaction responses 0mutez p.callback

let transfer (txs, validate_op, ops_storage, ledger, reverse_ledger
    : (transfer list) * operator_validator * operator_storage * ledger * reverse_ledger) : ledger * reverse_ledger =
  let make_transfer = (fun ((l, rv_l), tx : (ledger * reverse_ledger) * transfer) ->
    List.fold 
      (fun ((ll, rv_ll), dst : (ledger * reverse_ledger) * transfer_destination) ->
        if dst.amount = 0n
        then ll, rv_ll
        else if dst.amount <> 1n
        then (failwith fa2_insufficient_balance : ledger * reverse_ledger)
        else
          let owner = Big_map.find_opt dst.token_id ll in
          match owner with
          | None -> (failwith fa2_token_undefined : ledger * reverse_ledger)
          | Some o -> 
            if o <> tx.from_
            then (failwith fa2_insufficient_balance : ledger * reverse_ledger)
            else 
              begin
                let _u = validate_op (o, Tezos.sender, dst.token_id, ops_storage) in
                let new_ll = Big_map.update dst.token_id (Some dst.to_) ll in
                let new_rv_ll = 
                  match Big_map.find_opt tx.from_ rv_ll with
                  | None -> (failwith fa2_insufficient_balance : reverse_ledger)
                  | Some tk_id_l -> 
                      Big_map.update 
                        tx.from_ 
                        (Some (List.fold (
                          fun (new_list, token_id: token_id list * token_id) ->
                            if token_id = dst.token_id
                            then new_list
                            else token_id :: new_list
                        ) tk_id_l ([]: token_id list))) 
                        rv_ll 
                in
                let updated_rv_ll = 
                  match Big_map.find_opt dst.to_ new_rv_ll with
                  | None -> Big_map.add dst.to_ [dst.token_id] new_rv_ll
                  | Some tk_id_l -> Big_map.update dst.to_ (Some (dst.token_id :: tk_id_l)) new_rv_ll in

                new_ll, updated_rv_ll
              end
      ) tx.txs (l, rv_l)
  )
  in 
    
  List.fold make_transfer txs (ledger, reverse_ledger)

let find_token_def (tid, token_defs : token_id * (token_def set)) : token_def =
  let tdef = Set.fold (fun (res, d : (token_def option) * token_def) ->
    match res with
    | Some _ -> res
    | None ->
      if tid >= d.from_ && tid < d.to_
      then  Some d
      else (None : token_def option)
  ) token_defs (None : token_def option)
  in
  match tdef with
  | None -> (failwith fa2_token_undefined : token_def)
  | Some d -> d

let get_metadata (tokens, meta : (token_id list) * token_storage )
    : token_metadata list =
  List.map (fun (tid: token_id) ->
    let tdef = find_token_def (tid, meta.token_defs) in
    let meta = Big_map.find_opt tdef meta.metadata in
    match meta with
    | Some m -> { m with token_id = tid; }
    | None -> (failwith "NO_DATA" : token_metadata)
  ) tokens

//Entrypoint function to return the value of answer hash
let get_answer_hash (get_answer_param, token_storage : get_answer_parameters * token_metadata_storage) : operation = 
  let metadata_record = 
    match (Big_map.find_opt get_answer_param.token_id token_storage) with
    | None -> (failwith "NO DATA FOUND") 
    | Some m -> m in
  let buy_params : buy_token_parameters =
    {
      sent_answer_hash = metadata_record.answer_hash;
      recieved_answer_hash = get_answer_param.sent_answer_hash;
      token_id = get_answer_param.token_id  
    } in
  Tezos.transaction buy_params 0mutez get_answer_param.contract_reference

let mint (p, s: mint_params * nft_token_storage): nft_token_storage =
  let token_id = s.next_token_id in
  let new_ledger = Big_map.add token_id p.owner s.ledger in
  let new_reverse_ledger = 
    match Big_map.find_opt p.owner s.reverse_ledger with
    | None -> Big_map.add p.owner [token_id] s.reverse_ledger
    | Some l -> Big_map.update p.owner (Some (token_id :: l)) s.reverse_ledger in
  //storing answer hash in token_metadata
  let answer_hash = Crypto.sha256 (Bytes.pack (p.answer)) in 
  let new_entry = { token_id = token_id; token_info = Map.literal [("", p.link_to_metadata)] ; answer_hash = answer_hash} in
  { 
      s with 
          ledger = new_ledger;
          reverse_ledger = new_reverse_ledger;
          token_metadata = Big_map.add token_id new_entry s.token_metadata;
          next_token_id = token_id + 1n;
  }

let burn (p, s: token_id * nft_token_storage): nft_token_storage =
  let new_ledger: ledger =
    match Big_map.find_opt p s.ledger with
    | None -> (failwith "UNKNOWN_TOKEN": ledger)
    | Some owner ->
      if owner <> Tezos.sender
      then (failwith "NOT_TOKEN_OWNER": ledger)
      else
        Big_map.remove p s.ledger
  in
  let new_reverse_ledger: reverse_ledger =
    match Big_map.find_opt Tezos.sender s.reverse_ledger with
    | None -> (failwith "NOT_A_USER": reverse_ledger)
    | Some tk_id_l -> 
      Big_map.update 
        Tezos.sender 
        (Some (List.fold (
          fun (new_list, token_id: token_id list * token_id) ->
            if token_id = p
            then new_list
            else token_id :: new_list
        ) tk_id_l ([]: token_id list))) 
        s.reverse_ledger
  in { s with ledger = new_ledger; reverse_ledger = new_reverse_ledger }

let main (param, storage : fa2_entry_points * nft_token_storage)
    : (operation  list) * nft_token_storage =
  match param with
  | Transfer txs ->
    let (new_ledger, new_reverse_ledger) = transfer 
      (txs, default_operator_validator, storage.operators, storage.ledger, storage.reverse_ledger) in
    let new_storage = { storage with ledger = new_ledger; reverse_ledger = new_reverse_ledger } in
    ([] : operation list), new_storage

  | Balance_of p ->
    let op = get_balance (p, storage.ledger) in
    [op], storage

  | Update_operators updates ->
    let new_ops = fa2_update_operators (updates, storage.operators) in
    let new_storage = { storage with operators = new_ops; } in
    ([] : operation list), new_storage

  | Mint p ->
    ([]: operation list), mint (p, storage)

  | Burn p ->
    ([]: operation list), burn (p, storage)
  //Added the entrypoint for getting answer hash from another contract  
  | GetAnswerHash p ->
    let op = get_answer_hash (p, storage.token_metadata) in 
    [op], storage
