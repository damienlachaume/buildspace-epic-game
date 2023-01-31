// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";
import "hardhat/console.sol";

contract MyEpicGame is ERC721 {
    struct CharacterAttributes {
        uint256 characterIndex;
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
    }

    struct Troll {
        string name;
        string imageURI;
        uint256 hp;
        uint256 maxHp;
        uint256 attackDamage;
    }

    Troll public troll;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    CharacterAttributes[] defaultCharacters;

    mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

    mapping(address => uint256) public nftHolders;

    event CharacterNFTMinted(
        address sender,
        uint256 tokenId,
        uint256 CharacterIndex
    );
    event AttackComplete(
        address sender,
        uint256 newTrollHp,
        uint256 newCharacterHp
    );

    constructor(
        string[] memory characterNames,
        string[] memory characterImageURIs,
        uint256[] memory characterHp,
        uint256[] memory characterAttackDmg,
        string memory trollName,
        string memory trollImageURI,
        uint256 trollHp,
        uint256 trollAttackDamage
    ) ERC721("BeatTheTroll", "BTT") {
        troll = Troll({
            name: trollName,
            imageURI: trollImageURI,
            hp: trollHp,
            maxHp: trollHp,
            attackDamage: trollAttackDamage
        });

        console.log(
            "Done initializing troll %s w/ HP %s, img %s",
            troll.name,
            troll.hp,
            troll.imageURI
        );

        for (uint256 i = 0; i < characterNames.length; i += 1) {
            defaultCharacters.push(
                CharacterAttributes({
                    characterIndex: i,
                    name: characterNames[i],
                    imageURI: characterImageURIs[i],
                    hp: characterHp[i],
                    maxHp: characterHp[i],
                    attackDamage: characterAttackDmg[i]
                })
            );

            CharacterAttributes memory c = defaultCharacters[i];

            console.log(
                "Done initializing %s w/ HP %s, img %s",
                c.name,
                c.hp,
                c.imageURI
            );
        }

        _tokenIds.increment();
    }

    function mintCharacterNFT(uint256 _characterIndex) external {
        uint256 newItemId = _tokenIds.current();

        _safeMint(msg.sender, newItemId);

        nftHolderAttributes[newItemId] = CharacterAttributes({
            characterIndex: _characterIndex,
            name: defaultCharacters[_characterIndex].name,
            imageURI: defaultCharacters[_characterIndex].imageURI,
            hp: defaultCharacters[_characterIndex].hp,
            maxHp: defaultCharacters[_characterIndex].maxHp,
            attackDamage: defaultCharacters[_characterIndex].attackDamage
        });

        console.log(
            "Minted NFT w/ tokenId %s and characterIndex %s",
            newItemId,
            _characterIndex
        );

        nftHolders[msg.sender] = newItemId;

        _tokenIds.increment();

        emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);
    }

    function attackTroll() public {
        // Get the state of the player's NFT.
        uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
        CharacterAttributes storage character = nftHolderAttributes[
            nftTokenIdOfPlayer
        ];

        console.log(
            "\nPlayer w/ character %s about to attack. Has %s HP and %s AD",
            character.name,
            character.hp,
            character.attackDamage
        );
        console.log(
            "Troll %s has %s HP and %s AD",
            troll.name,
            troll.hp,
            troll.attackDamage
        );

        // Make sure the character has more than 0 HP.
        require(
            character.hp > 0,
            "Error: character must have HP to attack the troll."
        );

        // Make sure the troll has more than 0 HP.
        require(troll.hp > 0, "Error: troll must have HP to be attacked.");

        // Allow character to attack troll.
        if (troll.hp < character.attackDamage) {
            troll.hp = 0;
        } else {
            troll.hp = troll.hp - character.attackDamage;
        }

        // Allow troll to attack character.
        if (character.hp < troll.attackDamage) {
            character.hp = 0;
        } else {
            character.hp = character.hp - troll.attackDamage;
        }

        emit AttackComplete(msg.sender, troll.hp, character.hp);
        console.log("Character attacked troll. New troll hp: %s", troll.hp);
        console.log(
            "Troll attacked character. New character hp: %s\n",
            character.hp
        );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        CharacterAttributes memory charAttributes = nftHolderAttributes[
            _tokenId
        ];

        string memory strHp = Strings.toString(charAttributes.hp);
        string memory strMaxHp = Strings.toString(charAttributes.maxHp);
        string memory strAttackDamage = Strings.toString(
            charAttributes.attackDamage
        );

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                charAttributes.name,
                " -- NFT #: ",
                Strings.toString(_tokenId),
                '", "description": "This is an NFT that lets people play in the game Beat The Troll", "image": "',
                charAttributes.imageURI,
                '", "attributes": [ { "trait_type": "Health Points", "value": ',
                strHp,
                ', "max_value":',
                strMaxHp,
                '}, { "trait_type": "Attack Damage", "value": ',
                strAttackDamage,
                "} ]}"
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function checkIfUserHasNFT()
        public
        view
        returns (CharacterAttributes memory)
    {
        // Get the tokenId of the user's character NFT
        uint256 userNftTokenId = nftHolders[msg.sender];
        // If the user has a tokenId in the map, return their character.
        if (userNftTokenId > 0) {
            return nftHolderAttributes[userNftTokenId];
        }
        // Else, return an empty character.
        else {
            CharacterAttributes memory emptyStruct;
            return emptyStruct;
        }
    }

    function getAllDefaultCharacters()
        external
        view
        returns (CharacterAttributes[] memory)
    {
        return defaultCharacters;
    }

    function getTroll() external view returns (Troll memory) {
        return troll;
    }
}
