// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "forge-std/Test.sol";
import "../src/NFT.sol";
import "../src/NFTCollections.sol";
import "../src/NFTAuction.sol";
import "../src/NFTMarketplace.sol";

contract NFTTest is Test {
    NFT nft;
    NFTCollections collections;
    NFTAuction auction;
    NFTMarketplace marketplace;

    address owner = address(0x1);
    address user = address(0x2);

    function setUp() public {
        vm.startPrank(owner);

        nft = new NFT("TestNFT", "TNFT", address(0), address(0));
        collections = new NFTCollections(address(nft));
        auction = new NFTAuction(address(nft), address(0));
        marketplace = new NFTMarketplace(address(nft), address(collections), address(auction));

        nft.updateAuctionContract(address(auction));
        nft.updateMarketplaceContract(address(marketplace));

        vm.stopPrank();
    }

    function testMintNFT() public {
        vm.startPrank(owner);

        uint256 tokenId = nft.mint(owner, "ipfs://tokenURI", 1 ether, 1);
        assertEq(nft.ownerOf(tokenId), owner);

        vm.stopPrank();
    }

    function testCreateCollection() public {
        vm.startPrank(owner);

        uint256 collectionId = collections.createCollection(100, 500, 1 ether);
        NFTCollections.CollectionInfo memory collectionInfo = collections.getCollectionInfo(collectionId);
        assertEq(collectionInfo.collectionId, collectionId);
        assertTrue(collectionInfo.isActive);

        vm.stopPrank();
    }

    function testListNFT() public {
        vm.startPrank(owner);
            // First create a collection
        uint256 maxSupply = 100;
        uint256 royaltyPercentage = 250; // 2.5%
        uint256 floorPrice = 1 ether;
        collections.createCollection(maxSupply, royaltyPercentage, floorPrice);

        nft.setApprovalForAll(address(marketplace), true);
        uint256 tokenId = nft.mint(owner, "ipfs://tokenURI", 1 ether, 1);
        marketplace.listNFT(tokenId, 1 ether, NFTMarketplace.ListingType.SALE, 0, 0, 0);

        (address seller, , , , bool isActive, , ) = marketplace.getListingDetails(1);
        assertEq(seller, owner);
        assertTrue(isActive);

        vm.stopPrank();
    }

    function testPlaceBid() public {
        vm.startPrank(owner);

        nft.setApprovalForAll(address(auction), true);
        uint256 tokenId = nft.mint(owner, "ipfs://tokenURI", 1 ether, 1);
        uint256 auctionId = auction.createAuction(owner, tokenId, 1 ether, 1.5 ether, 1 days);

        vm.stopPrank();
        vm.startPrank(user);

        vm.deal(user, 2 ether);
        auction.placeBid{value: 1.1 ether}(tokenId);

        (, , , , , , address highestBidder, uint256 highestBid, , ) = auction.getAuction(auctionId);
        assertEq(highestBidder, user);
        assertEq(highestBid, 1.1 ether);

        vm.stopPrank();
    }

    function testCanMintNFTWithValidCollection() public {
        vm.startPrank(owner);
        
        // First create a collection
        uint256 maxSupply = 100;
        uint256 royaltyPercentage = 250; // 2.5%
        uint256 floorPrice = 1 ether;
        uint256 collectionId = collections.createCollection(maxSupply, royaltyPercentage, floorPrice);
        
        // Now mint with valid collection ID
        uint256 tokenId = nft.mint(owner, "ipfs://tokenURI", 1 ether, collectionId);
        
        // Verify the NFT was minted correctly
        assertEq(nft.ownerOf(tokenId), owner);
        assertEq(nft.getCollection(tokenId), collectionId);

        vm.stopPrank();
    }
}
