// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract SkyNft is Initializable, ERC721Upgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable{
    using StringsUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
   
    string public baseUrl;
    uint256 private _totalSupply;
  
   mapping(address => EnumerableSetUpgradeable.UintSet) private _userTokens;
   mapping(address => bool) public isMint;
  /**
   * @dev Initialization parameters
   */
   function initialize() public initializer {
     __Ownable_init();
     __ReentrancyGuard_init();
     __ERC721_init('Silky Nft', 'SKY NFT');

     baseUrl = '';
   }
  
  function setUrl (string memory url) external onlyOwner {
    baseUrl = url;
  }
 
   function mint() external nonReentrant returns(uint256 nftId){
     require(!isMint[msg.sender], 'have mint');
     _totalSupply = _totalSupply + 1;
     uint256 id = _totalSupply;
     isMint[msg.sender] = true;
     _safeMint(msg.sender, id);
    
     return id;
  }
  function totalSupply () external view returns(uint256) {
    return _totalSupply;
  }
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
       return string(
                abi.encodePacked(
                                '{"name":"',
                                "Magellanic Cloud Card #",
                                 _tokenId.toString(),
                                '", "image": "',
                                baseUrl,
                                '"',
                                '}'
                            )
            );
    }
 
  
  function getUserAllTokens (address _user) external view returns(uint256[] memory tokenIds){
    uint256 length = _userTokens[_user].length();
    tokenIds = new uint256[](length);
    for(uint256 i = 0; i < length; i++){
      tokenIds[i] = _userTokens[_user].at(i);
    }  
  }
  
  function _afterTokenTransfer(address from, address to,uint256 tokenId, uint256 batchSize) internal override virtual {
    if(from != address(0)) {
      _userTokens[from].remove(tokenId);
    
    }
    if(to == address(0)) {
      _totalSupply = _totalSupply - 1;
    }
    if(to != address(0)) {
      _userTokens[to].add(tokenId);  
    }
  }
}
