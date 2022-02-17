# lumina-contracts

This repository contains all public contracts of the Lumina Cash project.

## Project

Lumina is a new mining token on the Polygon (MATIC) network that is optimized to
make cryptomining easy and profitable for every cryptominer. Lumina’s ultimate goal is
to create a cryptocurrency that is an effective store of value by introducing a more
efficient and democratic crypto mining process.

## Contracts

- **Lumina Token Contract** (LuminaToken.sol) - standard ERC20 token contract
- **Lumina Records Contract** (LuminaRecords.sol) - keeps track of registered balances
- **Lumina Admin Contract** (ILuminaAdmin.sol) - maintains existing challenges and generates new challenges (public interface only)
- **Lumina Trustee Contract** (LuminaTrustee.sol) - owns lumina coins to be distributed to miners. Verifies and executes all mining claims.
- **Lumina Locker Contract** (ProgressContractLocker.sol) - owns locked lumina coins and allows their withdrawal in the amount proportional to the number of coins distributed by the trustee
- **Lumina Marketing Contract** (ILuminaMarketing.sol) - maintains referral data and executes market campaign logic paying additional rewards to promoters, marketers, and influencers from separate funds. This contract can optionally be connected to the trustee contract, so it gets notified any time a claim is made by miners  (public interface only)

## Links

* **Website:** [https://lumina.cash](https://lumina.cash)
* **Github:** [https://github.com/luminacash/lumina-contracts.git](https://github.com/luminacash/lumina-contracts.git)

## License

MIT
