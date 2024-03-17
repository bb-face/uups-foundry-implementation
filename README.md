## Test answer

### Use Solidity version ^0.8.0 (please pick a version and explain why you used it).

I selected Solidity version ^0.8.20 for its introduction of overflow and underflow checks, custom errors and compatibility with OpenZeppelin version 5. Newer versions carry the risk of potential new bugs/exploits. Since subsequent updates haven't offered significant new features essential to my project ^0.8.20 feels like a good balance between security and stability.

### Explain why you use which upgradable contract as a base and how you prevent storage collision.

To make the contract upgradable I used the UUPS proxy pattern with EIP1967 storage slots in order to avoid storage collisions.
In the context of this contract I could also have used the transparent proxy pattern, but I like the separation between admin and normal users and the possibility of removing the upgradability feature eventually.

### Screenshot any static analyzers you use and list the names in the readme.
There's the `slither.txt` file in the repo with the Slither report of the codebase.
Notice that the error `CollateralManagerV2 (src/CollateralManagerV2.sol#6-10) is an upgradeable contract that does not protect its initialize functions` is a false positive (more info here: https://github.com/crytic/slither/issues/1029)