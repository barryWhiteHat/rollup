
pragma solidity ^0.5.0;

import '../node_modules/openzeppelin-solidity/contracts/ownership/Ownable.sol';
import './lib/RollupHelpers.sol';

/**
 * @dev Define interface stakeManager contract
 */
contract StakeManager {
  function blockForged(uint128 entropy, address operator) returns(address);
}

/**
 * @dev Define interface Verifier contract
 */
contract Verifier {
  function verifyProof( uint[2] memory a, uint[2][2] memory b,
    uint[2] memory c, uint[8] memory input) view public returns (bool r);
}

contract Rollup is Ownable, RollupHelpers {

  // External contracts used
  Verifier verifier;
  StakeManager stakeManager;

  // Minim collateral required to commit for a block
  uint constant MIN_COMMIT_COLLATERAL = 1 ether;

  // Blocks that the operator can forge
  uint constant MAX_COMMIT_BLOCKS = 150; 

  /**
   * @dev global variales
   * Function: Commit a block
   */
  // Operator that is commited to forge the block
  address commitedOperator;     
  // Balance staked for operators at the time to commit a block
  uint balanceCommited;
  // Block where the commit is not valid any more
  uint commitBlockExpires;
  // Root commited
  bytes32 rootCommited;


  bytes32[] stateRoots;
  bytes32[] exitRoots;

  // List of ERC20 tokens
  address[] tokens;

  // Last account id to add into the side chain
  uint lastAssignedIdx;

  // Hash of the OnChain TXs list that will be mined in the next block
  bytes32 miningOnChainTxsHash;   

  // Hash of the OnChain TXs list that will be mined in two blocks
  // New onChain TX goes to this list, either deposit or forceWithdraw
  bytes32 fillingOnChainTxsHash;

  /**
   * @dev constructor
   */
  constructor(address _verifier, address _poseidon) RollupHelpers(_poseidon) public {
    verifier = Verifier(_verifier);
    address _stakeManager = new StakeManager(address(this));
    stakeManager = StakeManager(_stakeManager);
    owner = msg.sender;
  }

  /**
   * @dev check if the last root commited have not been forged
   * by checking the blocks that the operator is able to forge
   * the block
   */
  function resetCommitState() public {
    require( block.number > commitBlockExpires );
    require( commitedOperator != address(0) );
    // burn balance staked by the operator
    address(0).transfer(balanceCommited);
    // reset commit variables
    balanceCommited = 0;
    commitedOperator = address(0);
  }

  // /**
  //  * @dev operator commits the new block along with a deposit
  //  * operator has a certain amount of blocks to validate the bock commited
  //  * fees and deposit are paied to operator if block is finally added succesfully
  //  * otherwise, deposit is burned and new block commit would be available again 
  //  * @param newRoot new sidechain root commited
  //  */
  // function commitToBlock( bytes32 newRoot ) public payable {
  //   // Ensure there is no current block commited
  //   require( commitedOperator == address(0) );
  //   require( block.number > commitBlockExpires );
  //   // Ensure msg.sender has enough balance to commit a new root
  //   require( msg.value >= MIN_COMMIT_COLLATERAL );
  //   // Stake balance
  //   balanceCommited = msg.value; 
  //   // Set last block to forge the root
  //   commitBlockExpires = block.number + MAX_COMMIT_BLOCKS;
  //   // Save operator that commited the root
  //   commitedOperator = msg.sender;
  //   // Save the root
  //   rootCommited = newRoot;
 // }

  /**
   * @dev Checks proof given by the operator
   * forge the block if succesfull, burn operator stake otherwise
   * @param proofA zero knowledge input
   * @param proofB zero knowledge input
   * @param proofC zero knowledge input
   * @param newStateRoot new root to add in rootStates
   * @param exitRoot root of all exit transaction
   * @param feePlan fee operator plan
   * @param nTxPerCoin number of transmission per coin in order to calculate total fees
   * @param compressedTxs data availability to maintain sidecain
   * @param beneficiary address destination to receive fee transactions 
   */
  function forgeBlock( uint[2] memory proofA, uint[2][2] memory proofB, uint[2] memory proofC,
    bytes32 newStateRoot, bytes32 exitRoot, uint32[2] memory feePlan, uint32 nTxPerCoin,
    bytes memory compressedTxs) public {
    // Public Parameters of the circuit
      // [] newStateRoot,
      // [] exitRoot
      // [] feePlan[2]
      // [] nTxPerCoin
      // [] Hash(compressedTxs)
      // [] miningOnChainTxsHash
    
      uint[8] memory input;

      verifier.verifyProof(proofA, proofB, proofC, input);


    // Verify circuit
      // code public inputs to have uint[x]
        // hash of compressed tx
        // get miningOnChainTxsHash
    
    // Calculate fees
      // feePlan & nTxPerCoin
      // Send fees to beneficiary
      
    // EXpose transacction through events ?

    // Call Stake SmartContract to 
      stakeManager.blockForged(hash(proof), msg.sender);


      miningOnChainTxsHash = fillingOnChainTxsHash;
      fillingOnChainTxsHash = 0;
  }

  // TODO: Deposit fees?
  function deposit(
      uint depositAmount,
      uint token,
      uint[2] memory babyPubKey,
      uint to,                // In the TX deposit, it allows to do a send during deposit
      uint sendAmount,
      address withdrawAddress
  ) payable public {
      // create leaf with nonce = 0
      // each tx Off-Chain will increase nonce
      lastAssignedIdx++;
      // TODO: pseudo-code
      // fillingOnChainTxsHash = hash(fillingOnChainTxsHash, thisTx);
  }

  // TODO:
  // 
  function withdraw(
      uint idx,
      uint amount,
      uint coin,
      bytes32 exitRoot,
      bytes memory merkleProof // proof that leaf is on exit merkle tree, Amount & coin matches Idx & msg.sender
  ) public {

  }

  // TODO:
  // include fee to all on-chain transactions 
  function forceFullWithdrawFee(
      uint idx,
      bytes memory proofIdxHasWithdrawAddress,
      uint blockState
  ) public {
    // retrieve root from block, ensure root is the root on the proof 
    // get leaf info
    // fill leaf with msg.sender
    // check proofIdxHasWithdrawAddress
    // Event with Data
    // Updte hash --> fillingOnChainTxsHash = hash(fillingOnChainTxsHash, thisTx);
  }

  function addToken(address newToken) public onlyOwner {
      assert(tokens.length<0xFFFF);
      tokens.push(newToken);
  }

  //////////////
  // Viewers
  /////////////

  /**
   * @dev Retrieve root given its block depth
   * @return root
   */
  function getRoot(uint id) public view returns (bytes32) {
    return stateRoots[id];
  }


  /**
   * @dev Retrieve total number of blocks mined
   * @return Total number of blocks mined
   */
  function getDepth() public view returns (uint) {
    return stateRoots.length;
  }
}