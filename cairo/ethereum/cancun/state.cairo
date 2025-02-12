from starkware.cairo.common.cairo_builtins import PoseidonBuiltin, BitwiseBuiltin, KeccakBuiltin
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.default_dict import default_dict_new
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from legacy.utils.uint256 import uint256_add, uint256_sub
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.math_cmp import is_not_zero

from ethereum.cancun.fork_types import (
    Address,
    Account,
    OptionalAccount,
    MappingAddressAccount,
    MappingAddressAccountStruct,
    AddressAccountDictAccess,
    MappingAddressBytes32,
    MappingAddressBytes32Struct,
    AddressBytes32DictAccess,
    SetAddress,
    SetAddressStruct,
    SetAddressDictAccess,
    EMPTY_ACCOUNT,
    MappingTupleAddressBytes32U256,
    MappingTupleAddressBytes32U256Struct,
    Account__eq__,
    TupleAddressBytes32U256DictAccess,
    HashedTupleAddressBytes32,
    TupleAddressBytes32,
    ListTupleAddressBytes32,
    ListTupleAddressBytes32Struct,
)
from ethereum.cancun.trie import (
    get_tuple_address_bytes32_preimage_for_key,
    root,
    EthereumTries,
    EthereumTriesEnum,
    TrieTupleAddressBytes32U256,
    TrieTupleAddressBytes32U256Struct,
    TrieAddressOptionalAccount,
    TrieAddressOptionalAccountStruct,
    TrieBytesOptionalUnionBytesLegacyTransaction,
    TrieBytesOptionalUnionBytesLegacyTransactionStruct,
    TrieBytesOptionalUnionBytesReceipt,
    TrieBytesOptionalUnionBytesReceiptStruct,
    TrieBytesOptionalUnionBytesWithdrawal,
    TrieBytesOptionalUnionBytesWithdrawalStruct,
    TrieBytes32U256,
    TrieBytes32U256Struct,
    Bytes32U256DictAccess,
    MappingBytes32U256,
    MappingBytes32U256Struct,
    trie_get_TrieBytes32U256,
    trie_set_TrieBytes32U256,
    trie_get_TrieAddressOptionalAccount,
    trie_set_TrieAddressOptionalAccount,
    trie_get_TrieTupleAddressBytes32U256,
    trie_set_TrieTupleAddressBytes32U256,
    AccountStruct,
    copy_TrieAddressOptionalAccount,
    copy_TrieTupleAddressBytes32U256,
)
from ethereum.cancun.blocks import Withdrawal
from ethereum_types.bytes import Bytes, Bytes32
from ethereum_types.numeric import U256, U256Struct, Bool, bool, Uint
from ethereum.utils.numeric import U256_le, U256_sub, U256_add, U256_mul
from cairo_core.comparison import is_zero
from cairo_core.control_flow import raise

from legacy.utils.dict import (
    dict_read,
    hashdict_read,
    dict_write,
    hashdict_write,
    dict_new_empty,
    get_keys_for_address_prefix,
    dict_update,
    dict_copy,
    dict_squash,
)

struct AddressTrieBytes32U256DictAccess {
    key: Address,
    prev_value: TrieBytes32U256,
    new_value: TrieBytes32U256,
}

struct MappingAddressTrieBytes32U256Struct {
    dict_ptr_start: AddressTrieBytes32U256DictAccess*,
    dict_ptr: AddressTrieBytes32U256DictAccess*,
    // Unused
    parent_dict: MappingAddressTrieBytes32U256Struct*,
}

struct MappingAddressTrieBytes32U256 {
    value: MappingAddressTrieBytes32U256Struct*,
}

struct TupleTrieAddressOptionalAccountTrieTupleAddressBytes32U256Struct {
    trie_address_account: TrieAddressOptionalAccount,
    trie_tuple_address_bytes32_u256: TrieTupleAddressBytes32U256,
}

struct TupleTrieAddressOptionalAccountTrieTupleAddressBytes32U256 {
    value: TupleTrieAddressOptionalAccountTrieTupleAddressBytes32U256Struct*,
}

struct ListTupleTrieAddressOptionalAccountTrieTupleAddressBytes32U256Struct {
    data: TupleTrieAddressOptionalAccountTrieTupleAddressBytes32U256*,
    len: felt,
}

struct ListTupleTrieAddressOptionalAccountTrieTupleAddressBytes32U256 {
    value: ListTupleTrieAddressOptionalAccountTrieTupleAddressBytes32U256Struct*,
}

struct ListTrieTupleAddressBytes32U256Struct {
    data: TrieTupleAddressBytes32U256*,
    len: felt,
}

struct ListTrieTupleAddressBytes32U256 {
    value: ListTrieTupleAddressBytes32U256Struct*,
}

struct TransientStorageStruct {
    _tries: TrieTupleAddressBytes32U256,
}

struct TransientStorage {
    value: TransientStorageStruct*,
}

struct StateStruct {
    _main_trie: TrieAddressOptionalAccount,
    _storage_tries: TrieTupleAddressBytes32U256,
    created_accounts: SetAddress,
    original_storage_tries: TrieTupleAddressBytes32U256,
}

struct State {
    value: StateStruct*,
}

namespace StateImpl {
    func set_created_accounts{state: State}(new_created_accounts: SetAddress) {
        tempvar state = State(
            new StateStruct(
                _main_trie=state.value._main_trie,
                _storage_tries=state.value._storage_tries,
                created_accounts=new_created_accounts,
                original_storage_tries=state.value.original_storage_tries,
            ),
        );
        return ();
    }

    func set_original_storage_tries{state: State}(
        new_original_storage_tries: TrieTupleAddressBytes32U256
    ) {
        tempvar state = State(
            new StateStruct(
                _main_trie=state.value._main_trie,
                _storage_tries=state.value._storage_tries,
                created_accounts=state.value.created_accounts,
                original_storage_tries=new_original_storage_tries,
            ),
        );
        return ();
    }
}

func get_account_optional{poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address
) -> OptionalAccount {
    let trie = state.value._main_trie;
    with trie {
        let account = trie_get_TrieAddressOptionalAccount(address);
    }

    tempvar state = State(
        new StateStruct(
            _main_trie=trie,
            _storage_tries=state.value._storage_tries,
            created_accounts=state.value.created_accounts,
            original_storage_tries=state.value.original_storage_tries,
        ),
    );

    return account;
}

func get_account{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) -> Account {
    let account = get_account_optional{state=state}(address);

    if (cast(account.value, felt) == 0) {
        let empty_account = EMPTY_ACCOUNT();
        return empty_account;
    }

    tempvar res = Account(account.value);
    return res;
}

func set_account{poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address, account: OptionalAccount
) {
    let trie = state.value._main_trie;
    with trie {
        trie_set_TrieAddressOptionalAccount(address, account);
    }
    tempvar state = State(
        new StateStruct(
            _main_trie=trie,
            _storage_tries=state.value._storage_tries,
            created_accounts=state.value.created_accounts,
            original_storage_tries=state.value.original_storage_tries,
        ),
    );
    return ();
}

func move_ether{range_check_ptr, poseidon_ptr: PoseidonBuiltin*, state: State}(
    sender_address: Address, recipient_address: Address, amount: U256
) {
    alloc_locals;
    let sender_account = get_account(sender_address);
    let sender_balance = sender_account.value.balance;

    let is_sender_balance_sufficient = U256_le(amount, sender_balance);
    with_attr error_message("AssertionError") {
        assert is_sender_balance_sufficient.value = 1;
    }

    let new_sender_account_balance = U256_sub(sender_balance, amount);
    set_account_balance(sender_address, new_sender_account_balance);

    let recipient_account = get_account(recipient_address);
    let new_recipient_account_balance = U256_add(recipient_account.value.balance, amount);
    set_account_balance(recipient_address, new_recipient_account_balance);
    return ();
}

func process_withdrawal{range_check_ptr, poseidon_ptr: PoseidonBuiltin*, state: State}(
    withdrawal: Withdrawal
) {
    alloc_locals;

    let address = withdrawal.value.address;
    let amount = U256_mul(withdrawal.value.amount, U256(new U256Struct(10 ** 9, 0)));
    let account = get_account(address);
    let balance = account.value.balance;

    let new_balance = U256_add(balance, amount);
    set_account_balance(address, new_balance);
    return ();
}

func get_storage{poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address, key: Bytes32
) -> U256 {
    alloc_locals;
    let storage_tries = state.value._storage_tries;
    let value = trie_get_TrieTupleAddressBytes32U256{trie=storage_tries}(address, key);
    tempvar state = State(
        new StateStruct(
            _main_trie=state.value._main_trie,
            _storage_tries=storage_tries,
            created_accounts=state.value.created_accounts,
            original_storage_tries=state.value.original_storage_tries,
        ),
    );

    return value;
}

func destroy_account{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) {
    destroy_storage(address);
    let none_account = OptionalAccount(cast(0, AccountStruct*));
    set_account(address, none_account);
    return ();
}

func increment_nonce{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) {
    alloc_locals;
    let account = get_account(address);
    // This increment is safe since
    // `validate_transaction` will not allow a transaction
    // with a nonce equal to max nonce (u64 as of today)
    let new_nonce = account.value.nonce.value + 1;
    tempvar new_account = OptionalAccount(
        new AccountStruct(Uint(new_nonce), account.value.balance, account.value.code)
    );
    set_account(address, new_account);
    return ();
}
func set_storage{poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address, key: Bytes32, value: U256
) {
    alloc_locals;

    let storage_tries = state.value._storage_tries;
    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    // Assert that the account exists
    let account = get_account_optional(address);
    if (cast(account.value, felt) == 0) {
        raise('AssertionError');
    }
    let storage_trie = state.value._storage_tries;
    trie_set_TrieTupleAddressBytes32U256{poseidon_ptr=poseidon_ptr, trie=storage_trie}(
        address, key, value
    );

    // From EELS <https://github.com/ethereum/execution-specs/blob/master/src/ethereum/cancun/state.py#L318>:
    // if trie._data == {}:
    //     del state._storage_tries[address]
    // TODO: Investigate whether this is needed inside provable code
    // If the storage trie is empty, then write null ptr to the mapping address -> storage trie at address

    // 3. Update state with the updated storage tries
    tempvar state = State(
        new StateStruct(
            _main_trie=state.value._main_trie,
            _storage_tries=storage_trie,
            created_accounts=state.value.created_accounts,
            original_storage_tries=state.value.original_storage_tries,
        ),
    );
    return ();
}

func get_storage_original{range_check_ptr, poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address, key: Bytes32
) -> U256 {
    alloc_locals;

    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    let created_accounts_ptr = cast(state.value.created_accounts.value.dict_ptr, DictAccess*);
    let (is_created) = hashdict_read{dict_ptr=created_accounts_ptr}(1, &address.value);
    let new_created_accounts_ptr = cast(created_accounts_ptr, SetAddressDictAccess*);
    tempvar new_created_accounts = SetAddress(
        new SetAddressStruct(
            dict_ptr_start=state.value.created_accounts.value.dict_ptr_start,
            dict_ptr=new_created_accounts_ptr,
        ),
    );
    StateImpl.set_created_accounts(new_created_accounts);

    // In the transaction where an account is created, its preexisting storage
    // is ignored.
    if (is_created != 0) {
        tempvar res = U256(new U256Struct(0, 0));
        return res;
    }

    let new_original_storage_tries = state.value.original_storage_tries;
    let value = trie_get_TrieTupleAddressBytes32U256{trie=new_original_storage_tries}(address, key);

    // Update state
    tempvar state = State(
        new StateStruct(
            _main_trie=state.value._main_trie,
            _storage_tries=state.value._storage_tries,
            created_accounts=state.value.created_accounts,
            original_storage_tries=new_original_storage_tries,
        ),
    );

    return value;
}

func destroy_storage{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) {
    alloc_locals;

    let storage_tries = state.value._storage_tries;
    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    let prefix_len = 1;
    let prefix = &address.value;
    tempvar dict_ptr = cast(storage_tries.value._data.value.dict_ptr, DictAccess*);
    let keys = get_keys_for_address_prefix{dict_ptr=dict_ptr}(prefix_len, prefix);

    _destroy_storage_keys{poseidon_ptr=poseidon_ptr, storage_tries_ptr=dict_ptr}(keys, 0);
    let new_dict_ptr = cast(dict_ptr, TupleAddressBytes32U256DictAccess*);

    tempvar new_storage_tries_data = MappingTupleAddressBytes32U256(
        new MappingTupleAddressBytes32U256Struct(
            dict_ptr_start=storage_tries.value._data.value.dict_ptr_start,
            dict_ptr=new_dict_ptr,
            parent_dict=storage_tries.value._data.value.parent_dict,
        ),
    );

    tempvar new_storage_tries = TrieTupleAddressBytes32U256(
        new TrieTupleAddressBytes32U256Struct(
            storage_tries.value.secured, storage_tries.value.default, new_storage_tries_data
        ),
    );
    tempvar state = State(
        new StateStruct(
            _main_trie=state.value._main_trie,
            _storage_tries=new_storage_tries,
            created_accounts=state.value.created_accounts,
            original_storage_tries=state.value.original_storage_tries,
        ),
    );

    return ();
}

func _destroy_storage_keys{poseidon_ptr: PoseidonBuiltin*, storage_tries_ptr: DictAccess*}(
    keys: ListTupleAddressBytes32, index: felt
) {
    if (index == keys.value.len) {
        return ();
    }

    let current_key = keys.value.data[index];
    let key_len = 3;
    let (key) = alloc();
    assert key[0] = current_key.value.address.value;
    assert key[1] = current_key.value.bytes32.value.low;
    assert key[2] = current_key.value.bytes32.value.high;
    hashdict_write{dict_ptr=storage_tries_ptr}(key_len, key, 0);

    return _destroy_storage_keys{poseidon_ptr=poseidon_ptr, storage_tries_ptr=storage_tries_ptr}(
        keys, index + 1
    );
}

func get_transient_storage{poseidon_ptr: PoseidonBuiltin*, transient_storage: TransientStorage}(
    address: Address, key: Bytes32
) -> U256 {
    alloc_locals;
    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    let new_transient_storage_tries = transient_storage.value._tries;
    let value = trie_get_TrieTupleAddressBytes32U256{trie=new_transient_storage_tries}(
        address, key
    );

    tempvar transient_storage = TransientStorage(
        new TransientStorageStruct(new_transient_storage_tries)
    );

    return value;
}

func set_transient_storage{poseidon_ptr: PoseidonBuiltin*, transient_storage: TransientStorage}(
    address: Address, key: Bytes32, value: U256
) {
    alloc_locals;
    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    let new_transient_storage_tries = transient_storage.value._tries;
    trie_set_TrieTupleAddressBytes32U256{
        poseidon_ptr=poseidon_ptr, trie=new_transient_storage_tries
    }(address, key, value);

    // Trie is not deleted if empty
    // From EELS https://github.com/ethereum/execution-specs/blob/5c82ed6ac3eb992c7d87320a3e771b5e852a06df/src/ethereum/cancun/state.py#L697:
    // if trie._data == {}:
    //    del transient_storage._tries[address]
    tempvar transient_storage = TransientStorage(
        new TransientStorageStruct(new_transient_storage_tries)
    );

    return ();
}

func account_exists{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) -> bool {
    let account = get_account_optional(address);

    if (cast(account.value, felt) == 0) {
        tempvar result = bool(0);
        return result;
    }
    tempvar result = bool(1);
    return result;
}

func account_has_code_or_nonce{poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address
) -> bool {
    let account = get_account(address);

    if (account.value.nonce.value != 0) {
        tempvar res = bool(1);
        return res;
    }

    if (account.value.code.value.len != 0) {
        tempvar res = bool(1);
        return res;
    }

    tempvar res = bool(0);
    return res;
}

func account_has_storage{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) -> bool {
    alloc_locals;

    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    let storage_tries = state.value.original_storage_tries;
    let prefix_len = 1;
    let prefix = &address.value;
    tempvar dict_ptr = cast(storage_tries.value._data.value.dict_ptr, DictAccess*);
    let keys = get_keys_for_address_prefix{dict_ptr=dict_ptr}(prefix_len, prefix);
    let has_storage = is_not_zero(keys.value.len);
    tempvar res = bool(has_storage);
    return res;
}

func is_account_empty{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) -> bool {
    // Get the account at the address
    let account = get_account(address);

    // Check if nonce is 0, code is empty, and balance is 0
    if (account.value.nonce.value != 0) {
        tempvar res = bool(0);
        return res;
    }

    if (account.value.code.value.len != 0) {
        tempvar res = bool(0);
        return res;
    }

    if (account.value.balance.value.low != 0) {
        tempvar res = bool(0);
        return res;
    }

    if (account.value.balance.value.high != 0) {
        tempvar res = bool(0);
        return res;
    }

    tempvar res = bool(1);
    return res;
}

func mark_account_created{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) {
    alloc_locals;

    let created_accounts = state.value.created_accounts;

    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    let set_dict_ptr = cast(created_accounts.value.dict_ptr, DictAccess*);
    hashdict_write{poseidon_ptr=poseidon_ptr, dict_ptr=set_dict_ptr}(1, &address.value, 1);

    // Rebind state
    tempvar new_created_account = SetAddress(
        new SetAddressStruct(
            dict_ptr_start=created_accounts.value.dict_ptr_start,
            dict_ptr=cast(set_dict_ptr, SetAddressDictAccess*),
        ),
    );
    tempvar state = State(
        new StateStruct(
            _main_trie=state.value._main_trie,
            _storage_tries=state.value._storage_tries,
            created_accounts=new_created_account,
            original_storage_tries=state.value.original_storage_tries,
        ),
    );

    return ();
}

func account_exists_and_is_empty{poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address
) -> bool {
    alloc_locals;
    // Get the account at the address
    let account = get_account_optional(address);

    let _empty_account = EMPTY_ACCOUNT();
    let empty_account = OptionalAccount(_empty_account.value);
    let is_empty_account = Account__eq__(account, empty_account);

    return is_empty_account;
}

func is_account_alive{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) -> bool {
    alloc_locals;
    let account = get_account_optional(address);
    if (cast(account.value, felt) == 0) {
        tempvar res = bool(0);
        return res;
    }

    let _empty_account = EMPTY_ACCOUNT();
    let empty_account = OptionalAccount(_empty_account.value);
    let is_empty_account = Account__eq__(account, empty_account);

    if (is_empty_account.value == 0) {
        tempvar res = bool(1);
        return res;
    }

    tempvar res = bool(0);
    return res;
}

func begin_transaction{
    range_check_ptr,
    poseidon_ptr: PoseidonBuiltin*,
    state: State,
    transient_storage: TransientStorage,
}() {
    alloc_locals;

    let fp_and_pc = get_fp_and_pc();
    local __fp__: felt* = fp_and_pc.fp_val;

    // Set original storage tries if not already set
    if (cast(state.value.original_storage_tries.value, felt) == 0) {
        let storage_tries = state.value._storage_tries;
        let (new_dict_ptr_start, new_dict_ptr_end) = dict_copy(
            cast(storage_tries.value._data.value.dict_ptr_start, DictAccess*),
            cast(storage_tries.value._data.value.dict_ptr, DictAccess*),
        );
        tempvar original_storage_tries_data = MappingTupleAddressBytes32U256(
            new MappingTupleAddressBytes32U256Struct(
                dict_ptr_start=cast(new_dict_ptr_start, TupleAddressBytes32U256DictAccess*),
                dict_ptr=cast(new_dict_ptr_end, TupleAddressBytes32U256DictAccess*),
                parent_dict=cast(0, MappingTupleAddressBytes32U256Struct*),
            ),
        );
        tempvar original_storage_tries = TrieTupleAddressBytes32U256(
            new TrieTupleAddressBytes32U256Struct(
                secured=storage_tries.value.secured,
                default=storage_tries.value.default,
                _data=original_storage_tries_data,
            ),
        );
        tempvar range_check_ptr = range_check_ptr;
    } else {
        tempvar original_storage_tries = state.value.original_storage_tries;
        tempvar range_check_ptr = range_check_ptr;
    }

    // Copy the main trie
    let trie = state.value._main_trie;
    let copied_main_trie = copy_TrieAddressOptionalAccount{trie=trie}();

    // Copy the storage tries
    let storage_tries = state.value._storage_tries;
    let copied_storage_tries = copy_TrieTupleAddressBytes32U256{trie=storage_tries}();

    tempvar state = State(
        new StateStruct(
            _main_trie=copied_main_trie,
            _storage_tries=copied_storage_tries,
            created_accounts=state.value.created_accounts,
            original_storage_tries=original_storage_tries,
        ),
    );

    // Copy transient storage tries
    let transient_storage_tries = transient_storage.value._tries;
    let copied_transient_storage_tries = copy_TrieTupleAddressBytes32U256{
        trie=transient_storage_tries
    }();

    tempvar transient_storage = TransientStorage(
        new TransientStorageStruct(_tries=copied_transient_storage_tries)
    );

    return ();
}

func rollback_transaction{
    range_check_ptr,
    poseidon_ptr: PoseidonBuiltin*,
    state: State,
    transient_storage: TransientStorage,
}() {
    return close_transaction(drop=1);
}

func commit_transaction{
    range_check_ptr,
    poseidon_ptr: PoseidonBuiltin*,
    state: State,
    transient_storage: TransientStorage,
}() {
    return close_transaction(drop=0);
}

func close_transaction{
    range_check_ptr,
    poseidon_ptr: PoseidonBuiltin*,
    state: State,
    transient_storage: TransientStorage,
}(drop: felt) {
    alloc_locals;
    // State //

    // Main Trie
    let main_trie = state.value._main_trie;
    let main_trie_start = main_trie.value._data.value.dict_ptr_start;
    let main_trie_end = main_trie.value._data.value.dict_ptr;
    let parent_main_trie = main_trie.value._data.value.parent_dict;

    tempvar parent_main_trie_ptr = cast(parent_main_trie, felt);
    if (cast(parent_main_trie_ptr, felt) == 0) {
        raise('IndexError');
    }

    let parent_trie_start = parent_main_trie.dict_ptr_start;
    let parent_trie_end = parent_main_trie.dict_ptr;

    let (new_parent_trie_start, new_parent_trie_end) = dict_update(
        cast(main_trie_start, DictAccess*),
        cast(main_trie_end, DictAccess*),
        cast(parent_trie_start, DictAccess*),
        cast(parent_trie_end, DictAccess*),
        drop,
    );

    tempvar new_main_trie = TrieAddressOptionalAccount(
        new TrieAddressOptionalAccountStruct(
            secured=main_trie.value.secured,
            default=main_trie.value.default,
            _data=MappingAddressAccount(
                new MappingAddressAccountStruct(
                    dict_ptr_start=cast(new_parent_trie_start, AddressAccountDictAccess*),
                    dict_ptr=cast(new_parent_trie_end, AddressAccountDictAccess*),
                    parent_dict=parent_main_trie.parent_dict,
                ),
            ),
        ),
    );

    // Storage Tries
    let storage_tries = state.value._storage_tries;
    let storage_tries_start = storage_tries.value._data.value.dict_ptr_start;
    let storage_tries_end = storage_tries.value._data.value.dict_ptr;
    let parent_storage_tries = storage_tries.value._data.value.parent_dict;
    let parent_storage_tries_start = parent_storage_tries.dict_ptr_start;
    let parent_storage_tries_end = parent_storage_tries.dict_ptr;

    let (new_parent_storage_tries_dict_start, new_parent_storage_tries_dict) = dict_update(
        cast(storage_tries_start, DictAccess*),
        cast(storage_tries_end, DictAccess*),
        cast(parent_storage_tries_start, DictAccess*),
        cast(parent_storage_tries_end, DictAccess*),
        drop,
    );

    tempvar new_storage_tries = TrieTupleAddressBytes32U256(
        new TrieTupleAddressBytes32U256Struct(
            secured=storage_tries.value.secured,
            default=storage_tries.value.default,
            _data=MappingTupleAddressBytes32U256(
                new MappingTupleAddressBytes32U256Struct(
                    dict_ptr_start=cast(
                        new_parent_storage_tries_dict_start, TupleAddressBytes32U256DictAccess*
                    ),
                    dict_ptr=cast(
                        new_parent_storage_tries_dict, TupleAddressBytes32U256DictAccess*
                    ),
                    parent_dict=parent_storage_tries.parent_dict,
                ),
            ),
        ),
    );

    // If we're in the root state, we need to clear the created accounts
    let is_root_state = is_zero(cast(new_main_trie.value._data.value.parent_dict, felt));
    if (is_root_state != 0) {
        // Clear created accounts
        let (new_created_accounts_ptr) = dict_new_empty();
        tempvar new_created_accounts = SetAddress(
            new SetAddressStruct(
                dict_ptr_start=cast(new_created_accounts_ptr, SetAddressDictAccess*),
                dict_ptr=cast(new_created_accounts_ptr, SetAddressDictAccess*),
            ),
        );
    } else {
        tempvar new_created_accounts = state.value.created_accounts;
    }

    tempvar state = State(
        new StateStruct(
            _main_trie=new_main_trie,
            _storage_tries=new_storage_tries,
            created_accounts=new_created_accounts,
            original_storage_tries=state.value.original_storage_tries,
        ),
    );

    // Transient Storage //

    let transient_storage_tries = transient_storage.value._tries;
    let transient_storage_tries_start = transient_storage_tries.value._data.value.dict_ptr_start;
    let transient_storage_tries_end = transient_storage_tries.value._data.value.dict_ptr;
    let parent_transient_storage_tries = transient_storage_tries.value._data.value.parent_dict;

    tempvar parent_transient_storage_tries_ptr = cast(parent_transient_storage_tries, felt);
    if (cast(parent_transient_storage_tries_ptr, felt) == 0) {
        raise('IndexError');
    }

    let parent_transient_storage_tries_start = parent_transient_storage_tries.dict_ptr_start;
    let parent_transient_storage_tries_end = parent_transient_storage_tries.dict_ptr;
    let (
        new_parent_transient_storage_tries_start, new_parent_transient_storage_tries_end
    ) = dict_update(
        cast(transient_storage_tries_start, DictAccess*),
        cast(transient_storage_tries_end, DictAccess*),
        cast(parent_transient_storage_tries_start, DictAccess*),
        cast(parent_transient_storage_tries_end, DictAccess*),
        drop,
    );

    tempvar new_transient_storage_tries = TrieTupleAddressBytes32U256(
        new TrieTupleAddressBytes32U256Struct(
            secured=transient_storage_tries.value.secured,
            default=transient_storage_tries.value.default,
            _data=MappingTupleAddressBytes32U256(
                new MappingTupleAddressBytes32U256Struct(
                    dict_ptr_start=cast(
                        new_parent_transient_storage_tries_start, TupleAddressBytes32U256DictAccess*
                    ),
                    dict_ptr=cast(
                        new_parent_transient_storage_tries_end, TupleAddressBytes32U256DictAccess*
                    ),
                    parent_dict=parent_transient_storage_tries.parent_dict,
                ),
            ),
        ),
    );

    tempvar transient_storage = TransientStorage(
        new TransientStorageStruct(_tries=new_transient_storage_tries)
    );

    return ();
}

func set_code{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address, code: Bytes) {
    // Get the current account
    let account = get_account(address);

    // Create new account with updated code
    tempvar new_account = OptionalAccount(
        new AccountStruct(nonce=account.value.nonce, balance=account.value.balance, code=code)
    );

    // Set the updated account
    set_account(address, new_account);
    return ();
}

func set_account_balance{poseidon_ptr: PoseidonBuiltin*, state: State}(
    address: Address, amount: U256
) {
    let account = get_account(address);

    tempvar new_account = OptionalAccount(
        new AccountStruct(nonce=account.value.nonce, balance=amount, code=account.value.code)
    );

    set_account(address, new_account);
    return ();
}

func touch_account{poseidon_ptr: PoseidonBuiltin*, state: State}(address: Address) {
    let _account_exists = account_exists(address);
    if (_account_exists.value != 0) {
        return ();
    }

    let _empty_account = EMPTY_ACCOUNT();
    let empty_account = OptionalAccount(_empty_account.value);
    set_account(address, empty_account);
    return ();
}

func destroy_touched_empty_accounts{poseidon_ptr: PoseidonBuiltin*, state: State}(
    touched_accounts: SetAddress
) -> () {
    alloc_locals;

    // if current == end, return
    let current = touched_accounts.value.dict_ptr_start;
    let end = touched_accounts.value.dict_ptr;
    if (current == end) {
        return ();
    }

    let address = [current].key;

    // Check if current account exists and is empty, destroy if so
    let is_empty = account_exists_and_is_empty(address);
    if (is_empty.value != 0) {
        destroy_account(address);
        tempvar poseidon_ptr = poseidon_ptr;
        tempvar state = state;
    } else {
        tempvar poseidon_ptr = poseidon_ptr;
        tempvar state = state;
    }

    // Recurse with updated touched_accounts
    return destroy_touched_empty_accounts(
        SetAddress(
            new SetAddressStruct(
                dict_ptr_start=cast(current + DictAccess.SIZE, SetAddressDictAccess*),
                dict_ptr=cast(end, SetAddressDictAccess*),
            ),
        ),
    );
}

func storage_roots{
    range_check_ptr,
    bitwise_ptr: BitwiseBuiltin*,
    keccak_ptr: KeccakBuiltin*,
    poseidon_ptr: PoseidonBuiltin*,
}(state: State) -> MappingAddressBytes32 {
    alloc_locals;

    // Get the Trie[Tuple[Address, Bytes32], U256] storage tries, and squash them for unique keys
    let storage_tries = state.value._storage_tries;
    let storage_tries_start = cast(storage_tries.value._data.value.dict_ptr_start, DictAccess*);
    let storage_tries_end = cast(storage_tries.value._data.value.dict_ptr, DictAccess*);

    let (squashed_storage_tries_start, squashed_storage_tries_end) = dict_squash(
        storage_tries_start, storage_tries_end
    );

    // Create a Mapping[Address, Trie[Bytes32, U256]] that will contain the "flat" tries, where we
    // will get the storage trie of each address
    let (map_addr_storage_start) = default_dict_new(0);
    tempvar map_addr_storage = MappingAddressTrieBytes32U256(
        new MappingAddressTrieBytes32U256Struct(
            dict_ptr_start=cast(map_addr_storage_start, AddressTrieBytes32U256DictAccess*),
            dict_ptr=cast(map_addr_storage_start, AddressTrieBytes32U256DictAccess*),
            parent_dict=cast(0, MappingAddressTrieBytes32U256Struct*),
        ),
    );

    build_map_addr_storage_trie{
        map_addr_storage=map_addr_storage, storage_tries_ptr_end=storage_tries_end
    }(storage_tries_start);

    // Squash the Mapping[address, trie[bytes32, u256]] to iterate over each address
    let (squashed_map_addr_storage_start, squashed_map_addr_storage_end) = dict_squash(
        cast(map_addr_storage.value.dict_ptr_start, DictAccess*),
        cast(map_addr_storage.value.dict_ptr, DictAccess*),
    );

    tempvar map_addr_storage = MappingAddressTrieBytes32U256(
        new MappingAddressTrieBytes32U256Struct(
            dict_ptr_start=cast(squashed_map_addr_storage_start, AddressTrieBytes32U256DictAccess*),
            dict_ptr=cast(squashed_map_addr_storage_end, AddressTrieBytes32U256DictAccess*),
            parent_dict=cast(0, MappingAddressTrieBytes32U256Struct*),
        ),
    );

    // Create a Mapping[Address, Bytes32] that will contain the storage root of each address's
    // storage trie
    let (map_addr_storage_root_start) = default_dict_new(0);
    tempvar map_addr_storage_root = MappingAddressBytes32(
        new MappingAddressBytes32Struct(
            dict_ptr_start=cast(map_addr_storage_root_start, AddressBytes32DictAccess*),
            dict_ptr=cast(map_addr_storage_root_start, AddressBytes32DictAccess*),
            parent_dict=cast(0, MappingAddressBytes32Struct*),
        ),
    );

    // Iterate over each address, and get the root of its storage trie
    let map_addr_storage_ptr = cast(
        squashed_map_addr_storage_start, AddressTrieBytes32U256DictAccess*
    );
    let map_addr_storage_ptr_end = cast(
        squashed_map_addr_storage_end, AddressTrieBytes32U256DictAccess*
    );
    build_map_addr_storage_root{
        map_addr_storage_root=map_addr_storage_root,
        map_addr_storage_ptr_end=map_addr_storage_ptr_end,
    }(map_addr_storage_ptr);

    return map_addr_storage_root;
}

// @notice Builds a Mapping[Address, Bytes32] that contains the storage root of each address's
// storage trie
// @param map_addr_storage_root The mapping to write to
// @param map_addr_storage_ptr The pointer to the current address in the Mapping[Address, Trie[Bytes32, U256]]
// @param map_addr_storage_ptr_end The end of the Mapping[Address, Trie[Bytes32, U256]]
func build_map_addr_storage_root{
    range_check_ptr,
    bitwise_ptr: BitwiseBuiltin*,
    keccak_ptr: KeccakBuiltin*,
    poseidon_ptr: PoseidonBuiltin*,
    map_addr_storage_root: MappingAddressBytes32,
    map_addr_storage_ptr_end: AddressTrieBytes32U256DictAccess*,
}(map_addr_storage_ptr: AddressTrieBytes32U256DictAccess*) {
    alloc_locals;

    if (map_addr_storage_ptr == map_addr_storage_ptr_end) {
        return ();
    }

    let address = map_addr_storage_ptr.key;
    let storage_trie = map_addr_storage_ptr.new_value;

    tempvar union_trie = EthereumTries(
        new EthereumTriesEnum(
            account=TrieAddressOptionalAccount(cast(0, TrieAddressOptionalAccountStruct*)),
            storage=storage_trie,
            transaction=TrieBytesOptionalUnionBytesLegacyTransaction(
                cast(0, TrieBytesOptionalUnionBytesLegacyTransactionStruct*)
            ),
            receipt=TrieBytesOptionalUnionBytesReceipt(
                cast(0, TrieBytesOptionalUnionBytesReceiptStruct*)
            ),
            withdrawal=TrieBytesOptionalUnionBytesWithdrawal(
                cast(0, TrieBytesOptionalUnionBytesWithdrawalStruct*)
            ),
        ),
    );

    let storage_root = root(union_trie);

    let dict_ptr = cast(map_addr_storage_root.value.dict_ptr, DictAccess*);
    dict_write{dict_ptr=dict_ptr}(address.value, cast(storage_root.value, felt));

    tempvar map_addr_storage_root = MappingAddressBytes32(
        new MappingAddressBytes32Struct(
            dict_ptr_start=map_addr_storage_root.value.dict_ptr_start,
            dict_ptr=cast(dict_ptr, AddressBytes32DictAccess*),
            parent_dict=map_addr_storage_root.value.parent_dict,
        ),
    );

    // Squash the Trie[Bytes32, U256] - it won't ever be used again.
    let trie_ptr_start = storage_trie.value._data.value.dict_ptr_start;
    let trie_ptr_end = storage_trie.value._data.value.dict_ptr;
    dict_squash(cast(trie_ptr_start, DictAccess*), cast(trie_ptr_end, DictAccess*));

    return build_map_addr_storage_root(map_addr_storage_ptr + DictAccess.SIZE);
}

// @notice Builds a Mapping[Address, Trie[Bytes32, U256]] that contains the storage trie of each
// address
// @param map_addr_storage The mapping to write to
// @param storage_tries_ptr The pointer to the current entry in the Trie[Tuple[Address, Bytes32], U256]
// @param storage_tries_ptr_end The end of the Trie[Tuple[Address, Bytes32], U256]
func build_map_addr_storage_trie{
    range_check_ptr,
    poseidon_ptr: PoseidonBuiltin*,
    map_addr_storage: MappingAddressTrieBytes32U256,
    storage_tries_ptr_end: DictAccess*,
}(storage_tries_ptr: DictAccess*) {
    alloc_locals;

    if (storage_tries_ptr == storage_tries_ptr_end) {
        return ();
    }

    let tup_address_b32 = get_tuple_address_bytes32_preimage_for_key(
        storage_tries_ptr.key, storage_tries_ptr_end
    );
    build_storage_trie_for_address(
        tup_address_b32.value.address,
        tup_address_b32.value.bytes32,
        U256(cast(storage_tries_ptr.new_value, U256Struct*)),
    );

    return build_map_addr_storage_trie(storage_tries_ptr + DictAccess.SIZE);
}

// @notice Modifies a Trie[Bytes32, U256], the storage trie of an address, and adds it to the
// Mapping[Address, Trie[Bytes32, U256]]
// @param address The address to build the storage trie for
// @param key The key to add to the storage trie
// @param value The value to add to the storage trie
func build_storage_trie_for_address{
    range_check_ptr, poseidon_ptr: PoseidonBuiltin*, map_addr_storage: MappingAddressTrieBytes32U256
}(address: Address, key: Bytes32, value: U256) {
    alloc_locals;

    let dict_ptr = cast(map_addr_storage.value.dict_ptr, DictAccess*);

    // Get storage trie for address
    let (trie_ptr_) = dict_read{dict_ptr=dict_ptr}(address.value);
    if (cast(trie_ptr_, felt) == 0) {
        let (segment_start) = default_dict_new(0);
        tempvar default = new U256Struct(0, 0);
        tempvar trie_ptr = new TrieBytes32U256Struct(
            secured=bool(1),
            default=U256(default),
            _data=MappingBytes32U256(
                new MappingBytes32U256Struct(
                    dict_ptr_start=cast(segment_start, Bytes32U256DictAccess*),
                    dict_ptr=cast(segment_start, Bytes32U256DictAccess*),
                    parent_dict=cast(0, MappingBytes32U256Struct*),
                ),
            ),
        );
    } else {
        tempvar trie_ptr = cast(trie_ptr_, TrieBytes32U256Struct*);
    }

    // Modify storage trie for address
    let trie = TrieBytes32U256(trie_ptr);
    trie_set_TrieBytes32U256{poseidon_ptr=poseidon_ptr, trie=trie}(key, value);

    // Update the mapping address -> trie
    dict_write{dict_ptr=dict_ptr}(address.value, cast(trie.value, felt));
    tempvar map_addr_storage = MappingAddressTrieBytes32U256(
        new MappingAddressTrieBytes32U256Struct(
            dict_ptr_start=map_addr_storage.value.dict_ptr_start,
            dict_ptr=cast(dict_ptr, AddressTrieBytes32U256DictAccess*),
            parent_dict=map_addr_storage.value.parent_dict,
        ),
    );

    return ();
}
