type token_supply = 
[@layout:comb]
{
    current_stock: nat;
    price: tez;
}
type token_shop_storage = (nat, token_supply) map

type return = operation list * token_shop_storage
//hardcoded values for testing
let nft_contract_address : address = ("tz1euwFCxPzdRdpZUEsQPs5NSDXHvnQZP3aL" : address)
let owner_address : address = ("tz1euwFCxPzdRdpZUEsQPs5NSDXHvnQZP3aL": address)

// FA2 types declaration
type token_id = nat
type transfer_destination = 
[@layout:comb]
{
    _to: address;
    token_id: token_id;
    amount: nat;
}
type transfer = 
[@layout:comb]
{
    from_: address;
    txs: transfer_destination list;
}

type token_buy_parameters = {
    token_id : token_id;
}

type answer_hash = bytes

type buy_token_parameters = 
[@layout:comb]
{
    sent_answer_hash : answer_hash;
    recieved_answer_hash : answer_hash;
    token_id : token_id;
}

type get_answer_parameters = 
[@layout:comb]
{
    token_id : token_id;
    sent_answer_hash : answer_hash;
    contract_reference : (buy_token_parameters) contract; 
}
type initiate_buy_parameters = 
[@layout:comb]
{
    token_id : token_id;
    answer : string;
}
type token_metadata =
[@layout:comb]
{
  token_id : token_id;
  token_info : (string, bytes) map;
  answer_hash : answer_hash;
}

type token_shop_entrypoints = 
    | InitiateBuy of initiate_buy_parameters
    | FinallyBuyToken of buy_token_parameters

type token_metadata_storage = (token_id, token_metadata) big_map

let initiate_buying(initiate_buy_params, token_shop_storage : initiate_buy_parameters * token_shop_storage) : return =
    let sending_answer_hash : bytes = 
        Crypto.sha256(Bytes.pack(initiate_buy_params.answer)) in
    //referencing fa2 contract   
    let fa2_contract : (get_answer_parameters) contract= 
        match (Tezos.get_entrypoint_opt "%getAnswerHash" nft_contract_address : (get_answer_parameters) contract option) with
        | None -> (failwith "Contract reference cannot be made, Please check Contract Address!" : (get_answer_parameters) contract)
        | Some entr -> entr
    in
    let this_contract_reference : (buy_token_parameters) contract = 
        match (Tezos.get_entrypoint_opt "%finallyBuyToken" Tezos.self_address : (buy_token_parameters) contract option) with
        | None -> (failwith "Contract reference cannot be made, Please check Contract Address!" : (buy_token_parameters) contract)
        | Some entry -> entry in
    let answer_hash_param : get_answer_parameters = 
        { 
            token_id = initiate_buy_params.token_id;
            sent_answer_hash = sending_answer_hash;
            contract_reference = this_contract_reference;
        }
    in
    let tr = Tezos.transaction answer_hash_param 0mutez fa2_contract
    in
    [tr], token_shop_storage

let buy_token(buy_token_param, token_shop_storage : buy_token_parameters * token_shop_storage) : return = 
    //checking if answer hashes matches or not
    let () = if buy_token_param.sent_answer_hash <> buy_token_param.recieved_answer_hash then
     failwith ("Answer hashes not matching")
    in
    let token_kind : token_supply = 
        match Map.find_opt (buy_token_param.token_id) token_shop_storage with
        | Some(tok) -> tok
        | None -> failwith "Token has not been found Or has been sold out!"
    in
    let () = if Tezos.amount <> token_kind.price then
        failwith "Sorry, the token you are trying to buy has different price!"
    in
    let () = if token_kind.current_stock = 0n then
        failwith "Sorry the token you are trying to buy has been Sold Out or is Out of Stock!"
    in
    let token_shop_storage = Map.update
        buy_token_param.token_id (Some { token_kind with current_stock = abs (token_kind.current_stock - 1n) }) 
        token_shop_storage
    in 
    let tr : transfer = {
        from_ = Tezos.self_address;
        txs = 
        [
            {
                _to = Tezos.sender;
                token_id = 1n; //Hardcoded for example
                amount = abs (token_kind.current_stock - 1n);
            }
        ];
    } in
    let entrypoint : transfer list contract = 
        match ( Tezos.get_entrypoint_opt "%transfer" nft_contract_address : transfer list contract option ) with
        | None -> ( failwith "Invalid external token contract" : transfer list contract )
        | Some e -> e
    in
    let fa2_operation : operation =
        Tezos.transaction [tr] 0mutez entrypoint
    in
    let receiver : unit contract = 
        match (Tezos.get_contract_opt owner_address : unit contract option) with 
        | Some (contr) -> contr
        | None -> (failwith "Not a Contract" : (unit contract))
    in
    let payout_operation : operation = 
        Tezos.transaction unit amount receiver
    in 
    let operations : operation list =
        [ payout_operation; fa2_operation; ]
    in (( operations : operation list), token_shop_storage)

let main(param, stor : token_shop_entrypoints * token_shop_storage) : return = 
    match param with 
    | InitiateBuy (tkId) -> initiate_buying(tkId, stor)
    | FinallyBuyToken p -> buy_token(p, stor)
