# Util Contracts


## FeeOnTransferDetector
A lens contract to fetch Fee-on-transfer token buy and sell fees

### Deployment Addresses
| Chain Id | Deployment Address                         | V2 Factory                                 |
|----------|--------------------------------------------|--------------------------------------------|
| 1        | 0xbc708B192552e19A088b4C4B8772aEeA83bCf760 | 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f |
| 10       | 0x95aDC98A949dCD94645A8cD56830D86e4Cf34Eff | 0x0c3c1c532F1e39EdF36BE9Fe0bE1410313E074Bf |
| 56       | 0xCF6220e4496B091a6b391D48e770f1FbaC63E740 | 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6 |
| 137      | 0xC988e19819a63C0e487c6Ad8d6668Ac773923BF2 | 0x9e5A52f57b3038F1B8EeE45F28b3C1967e22799C |
| 8453     | 0xCF6220e4496B091a6b391D48e770f1FbaC63E740 | 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6 |
| 42161    | 0x37324D81e318260DC4f0fCb68035028eFdE6F50e | 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9 |
| 42220    | 0x8eEa35913DdeD795001562f9bA5b282d3ac04B60 | 0x79a530c8e2fA8748B7B40dd3629C0520c2cCf03f |
| 43114    | 0x8269d47c4910B8c87789aA0eC128C11A8614dfC8 | 0x5C346464d33F90bABaf70dB6388507CC889C1070 |

## FeeCollector
The collector of interface fees that will be swapped and sent to Uniswap Labs.

### Deployment Addresses
| Chain Id | Deployment Address                             | UniversalRouter Address                      | Permit2 Address                               | Fee Token Address                               |
|----------|------------------------------------------------|----------------------------------------------|-----------------------------------------------|-------------------------------------------------|
| 1        | 0x000000fee13a103A10D593b9AE06b3e05F2E7E1c | 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48      |
| 10       | 0x3d83ec320541aE96C4C91E9202643870458fB290 | 0xCb1355ff08Ab38bBCE60111F1bb2B784bE25D7e8   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0x0b2c639c533813f4aa9d7837caf62653d097ff85      |
| 137      | 0x23b5aa437CfDaF03235d78961e032dbA549dFc06 | 0xec7BE89e9d109e7e3Fec59c222CF297125FEFda2   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359      |
| 42161    | 0x89F30783108E2F9191Db4A44aE2A516327C99575 | 0x5E325eDA8064b456f4781070C0738d849c824258   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0xaf88d065e77c8cc2239327c5edb3a432268e5831      |
| 42220    | 0x21d06974F8863B1b0C236Bc3C5526DbF0051eaB5 | 0x643770E279d5D0733F21d6DC03A8efbABf3255B4   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0xcebA9300f2b948710d2653dD7B07f33A8B32118C      |
| 56       | 0x1D786eED79c8eE62a43e6B5263ea424866a4bf34 | 0x4Dae2f939ACf50408e13d58534Ff8c2776d45265   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0x8ac76a51cc950d9822d68b83fe1ad97b32cd580d      |
| 43114    | 0x1682f533c2359834167E5e4E108c1BfB69920e78 | 0x4Dae2f939ACf50408e13d58534Ff8c2776d45265   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E      |
| 8453     | 0x5d64D14D2CF4fe5fe4e65B1c7E3D11e18D493091 | 0x3fC91A3afd70395Cd496C647d5a6CC9D4B2b7FAD   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0x833589fcd6edb6e08f4c7c32d4f71b54bda02913      |
| 324      | 0xbCDdB5a0CB87166e1C1cc99A0f9736Be6f449dd8 | 0x28731BCC616B5f51dD52CF2e4dF0E78dD1136C06   | 0x0000000000225e31D15943971F47aD3022F714Fa    | 0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4      |
| 7777777  | 0x33352C573Ee093408F1424E1eD22911Dfb590a43 | 0x2986d9721A49838ab4297b695858aF7F17f38014   | 0x000000000022d473030f116ddee9f6b43ac78ba3    | 0xCccCCccc7021b32EBb4e8C08314bD62F7c653EC4      |
