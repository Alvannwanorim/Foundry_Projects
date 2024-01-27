## Solidity FundMe COntract

## About

THis code is to create a smart contract which can be used to donate to a wallet

## What can it do?

1. Users can send ethereum to this contract
2. Only the minimum ether amount or above is accepted
3. The contract owner can withdraw the donations to this contract.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
