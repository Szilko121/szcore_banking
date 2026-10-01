# szcore_banking

**SzCore Framework 1.4.0-rc1** · by **SzCode**

Player banking UI and server-authoritative deposit, withdrawal, transfer and transaction history.

## Installation

```bash
git clone https://github.com/Szilko121/szcore_banking.git resources/[szcore]/szcore_banking
```

Dependencies: `oxmysql`, `szcore`, `szcore_ui`.

## Public exports

- `DepositCash`
- `GetMyStatement`
- `GetStatement`
- `OpenBank`
- `TransferPlayerBank`
- `WithdrawCash`

The server owns all balance mutations. The NUI only submits requested actions.
