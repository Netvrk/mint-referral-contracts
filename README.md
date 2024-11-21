# NFT Mint & Referral System

This project implements a referral-based NFT minting system using Solidity smart contracts, where users can mint NFTs by referring others and earn rewards based on a referral factor. It consists of three contracts: AaReferral, MrReferral, and RootReferral, each tailored for a specific NFT collection.

The AaReferral contract uses a dynamic referral factor, calculated off-chain and verified with a Merkle root tree, offering flexibility. In contrast, the MrReferral and RootReferral contracts use predefined, fixed referral factors for simpler reward distribution.

- **AaReferral**

  - For Archetype Avatar NFTs.
  - Uses a dynamic referral factor calculated off-chain.
  - Verifies the referral factor with a Merkle root tree.

- **MrReferral**

  - For Minerunner NFTs (Axe).
  - Uses a predefined referral factor.

- **RootReferral**
  - For Netvrk OG NFTs (Land, Transport, Bonus Packs).
  - Uses a predefined referral factor.

## Goerli Test Network

- **NRGY Token:** [0x9DFD626221C2A88d38253dd90b09521DBa00108d](https://goerli.etherscan.io/address/0x9DFD626221C2A88d38253dd90b09521DBa00108d)
- **Aa NFT Address:** [0x96694a89BC38982824e8EfB8529ebe661EFDA6f6](https://goerli.etherscan.io/address/0x96694a89BC38982824e8EfB8529ebe661EFDA6f6)
- **Aa Referral Address:** [0x7DB065902Ac1637fB28937Bf2F10E2F40F882716](https://goerli.etherscan.io/address/0x7DB065902Ac1637fB28937Bf2F10E2F40F882716)
- **MR NFT Address:** [0x2b03343e45e637B8a994d07C5e3683bcf80C19c7](https://goerli.etherscan.io/address/0x2b03343e45e637B8a994d07C5e3683bcf80C19c7)
- **MR Referral Address:** [0xe2e96CD146cAfae6040B8b5F3c2fd6A9dFa830A3](https://goerli.etherscan.io/address/0xe2e96CD146cAfae6040B8b5F3c2fd6A9dFa830A3)
- **Root NFT Address:** [0x5abdcB5DB3ab19274466db268b0F44D8a253dDDb](https://goerli.etherscan.io/address/0x5abdcB5DB3ab19274466db268b0F44D8a253dDD

These contracts are experimental and are not used on the main networks. They are deployed on the Goerli test network for testing purposes.
