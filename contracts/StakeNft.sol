// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract StakeNft is Initializable, OwnableUpgradeable, ERC721HolderUpgradeable, ReentrancyGuardUpgradeable{
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  event StakeLog(address indexed user, address indexed nftAddress, uint256 tokenId, uint256 time);
  event WithdrawRewardLog(address indexed user, address indexed nftAddress,uint256 amount, uint256 time);
  event UnStakeLog(address indexed user, address indexed nftAddress, uint256 tokenId, uint256 time);
  
   struct Nft {
    address nftAddress;
    uint256 tokenId;
    uint256 lastTime;
  }
   address public nftAddress;
   address public rewardToken;
   uint256 public periodReward;
   uint256 public periodTime;
   address receiveAddress;
   uint256 public mintFee;

   mapping (address => EnumerableSetUpgradeable.UintSet) private userStakeIds;
   mapping(uint256 => Nft) public nftInfo;
   mapping(address => uint256) public lastWithdrawTime;

   function initialize() public initializer {
     __Ownable_init();
     __ReentrancyGuard_init();

     periodTime = 3600;
     periodReward = 10 * 1e18;
     mintFee = 0.0006 * 1e18;

     rewardToken = address(0xA9a026d3dAA909563a2541EbC64Ae44c61b76d8d);
     nftAddress = address(0xdC6065BC6B5B4dD32Ed8070C212F0CcE76Ee99A8);
     receiveAddress = address(0x093c52ecE3F4555DDC41451c9aA4e43119444D92);
   }
    function setReceiveAddress (address _receiveAddress) external onlyOwner {
    receiveAddress = _receiveAddress;
  }
   function setMintFee (uint256 _fee) external onlyOwner {
      mintFee = _fee;
   }
    function setPeriodTime(uint256 _periodTime) external onlyOwner {
      periodTime = _periodTime;
    }
    function setPeriodReward(uint256 _periodReward) external onlyOwner {
      periodReward = _periodReward;
    }
   function stakeNft(uint256 tokenId) external payable nonReentrant {
        require(IERC721Upgradeable(nftAddress).ownerOf(tokenId) == msg.sender, 'not owner');
        require(msg.value >= mintFee, 'stake fee is not enough');
         (bool success, ) = receiveAddress.call{value: msg.value}("");
         require(success, "Transfer failed.");
        if(nftInfo[tokenId].nftAddress == address(0)) {
          nftInfo[tokenId] = Nft(nftAddress, tokenId,block.timestamp);
        }
        nftInfo[tokenId].lastTime =  block.timestamp;
        userStakeIds[msg.sender].add(tokenId);
        IERC721Upgradeable(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        emit StakeLog(msg.sender, nftAddress, tokenId, block.timestamp);
      }
    function unStake (uint256 tokenId) external nonReentrant {
      require(userStakeIds[msg.sender].contains(tokenId), 'tokenId not stake');
       uint256 totalTime = (block.timestamp - nftInfo[tokenId].lastTime);
       uint256 totalNum = uint256(totalTime / periodTime);
       uint256 rewardNft = totalNum * periodReward;
       nftInfo[tokenId].lastTime = block.timestamp;
       IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, rewardNft);
       IERC721Upgradeable(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId);
      emit UnStakeLog(msg.sender, nftAddress, tokenId, block.timestamp); 
    }
    function getReward(address user) external view returns(uint256 reward){
      uint256 length = userStakeIds[user].length();
      for(uint256 i = 0; i < length; i++) {
        uint256 totalTime = (block.timestamp - nftInfo[userStakeIds[user].at(i)].lastTime);
        uint256 totalNum = uint256(totalTime / periodTime);
        uint256 rewardNft = totalNum * periodReward;
        reward += rewardNft;
      }
    }

    function withdrawReward() external nonReentrant{
      require(userStakeIds[msg.sender].length() > 0, 'no stake');
      if(lastWithdrawTime[msg.sender] != 0) {
         require(lastWithdrawTime[msg.sender] + 7 * 86400 <= block.timestamp, 'no enough 7 days');
      }
      lastWithdrawTime[msg.sender] = block.timestamp;
      
      uint256 reward = 0;
      uint256 length = userStakeIds[msg.sender].length();
      for(uint256 i = 0; i < length; i++) {
        uint256 totalTime = (block.timestamp - nftInfo[userStakeIds[msg.sender].at(i)].lastTime);
        uint256 totalNum = uint256(totalTime / periodTime);
        uint256 rewardNft = totalNum * periodReward;
        reward += rewardNft;
        nftInfo[userStakeIds[msg.sender].at(i)].lastTime = block.timestamp + totalNum * periodTime  - totalTime;
      }
      require(reward > 0, 'reward is 0');
      IERC20Upgradeable(rewardToken).safeTransfer(msg.sender, reward);
      emit WithdrawRewardLog(msg.sender, nftAddress, reward, block.timestamp);
    }
   function getUserStakeIds(address user) external view returns(uint256[] memory ids) {
     uint256 length = userStakeIds[user].length();
     ids = new uint256[](length);
     for(uint256 i = 0; i < length; i++) {
       ids[i] = userStakeIds[user].at(i);
     }
   }
  function getTokenToUser(uint256 amount, address token, address user) external onlyOwner{
    // require(isWhitelist(msg.sender), 'Insufficient caller is no isWhitelist');
    IERC20Upgradeable(token).safeTransfer(user, amount);
  }
    function getCurTime() external view returns (uint256) {
        return block.timestamp;
    }
}