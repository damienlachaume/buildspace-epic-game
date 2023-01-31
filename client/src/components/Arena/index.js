import React, { useEffect, useState } from "react";
import { ethers } from "ethers";
import { CONTRACT_ADDRESS, transformCharacterData } from "../../constants";
import myEpicGame from "../../utils/MyEpicGame.json";
import "./Arena.css";
import LoadingIndicator from "../LoadingIndicator";

/*
 * We pass in our characterNFT metadata so we can show a cool card in our UI
 */
const Arena = ({ characterNFT, setCharacterNFT, currentAccount }) => {
  // State
  const [gameContract, setGameContract] = useState(null);
  const [troll, setTroll] = useState(null);
  const [attackState, setAttackState] = useState("");
  const [showToast, setShowToast] = useState(false);

  useEffect(() => {
    const { ethereum } = window;

    if (ethereum) {
      const provider = new ethers.providers.Web3Provider(ethereum);
      const signer = provider.getSigner();
      const gameContract = new ethers.Contract(
        CONTRACT_ADDRESS,
        myEpicGame.abi,
        signer
      );

      setGameContract(gameContract);
    } else {
      console.log("Ethereum object not found");
    }
  }, []);

  useEffect(() => {
    const fetchTroll = async () => {
      const trollTxn = await gameContract.getTroll();
      console.log("Troll : ", trollTxn);
      setTroll(transformCharacterData(trollTxn));
    };

    /*
     * Setup logic when this event is fired off
     */
    const onAttackComplete = (from, newTrollHp, newCharacterHp) => {
      const trollHp = newTrollHp.toNumber();
      const characterHp = newCharacterHp.toNumber();
      const sender = from.toString();

      console.log(
        `AttackComplete: Troll Hp: ${trollHp} Character Hp: ${characterHp}`
      );

      if (currentAccount === sender.toLowerCase()) {
        setTroll((prevState) => {
          return { ...prevState, hp: trollHp };
        });
        setCharacterNFT((prevState) => {
          return { ...prevState, hp: characterHp };
        });
      } else {
        setTroll((prevState) => {
          return { ...prevState, hp: trollHp };
        });
      }
    };

    if (gameContract) {
      fetchTroll();
      gameContract.on("AttackComplete", onAttackComplete);
    }

    /*
     * Make sure to clean up this event when this component is removed
     */
    return () => {
      if (gameContract) {
        gameContract.off("AttackComplete", onAttackComplete);
      }
    };
  }, [currentAccount, gameContract, setCharacterNFT]);

  const runAttackAction = async () => {
    try {
      if (gameContract) {
        setAttackState("attacking");
        console.log("Attacking troll...");
        const txn = await gameContract.attackTroll();
        await txn.wait();
        console.log(txn);
        setAttackState("hit");

        setShowToast(true);
        setTimeout(() => {
          setShowToast(false);
        }, 5000);
      }
    } catch (error) {
      console.error("Error attacking troll:", error);
      setAttackState("");
    }
  };

  return (
    <div className="arena-container">
      {troll && characterNFT && (
        <div id="toast" className={showToast ? "show" : ""}>
          <div id="desc">{`💥 ${troll.name} was hit for ${characterNFT.attackDamage}!`}</div>
        </div>
      )}

      {/* Troll */}
      {troll && (
        <div className="troll-container">
          <div className={`troll-content  ${attackState}`}>
            <h2>🔥 {troll.name} 🔥</h2>
            <div className="image-content">
              <img
                src={troll.imageURI.replace("ipfs://", "https://ipfs.io/ipfs/")}
                alt={`Troll ${troll.name}`}
              />
              <div className="health-bar">
                <progress value={troll.hp} max={troll.maxHp} />
                <p>{`${troll.hp} / ${troll.maxHp} HP`}</p>
              </div>
            </div>
          </div>
          <div className="attack-container">
            <button className="cta-button" onClick={runAttackAction}>
              {`💥 Attack ${troll.name} 💥`}
            </button>
          </div>
          {attackState === "attacking" && (
            <div className="loading-indicator">
              <LoadingIndicator />
              <p>Attacking ⚔️</p>
            </div>
          )}
        </div>
      )}

      {/* Character NFT */}
      {characterNFT && (
        <div className="players-container">
          <div className="player-container">
            <h2>Your Character</h2>
            <div className="player">
              <div className="image-content">
                <h2>{characterNFT.name}</h2>
                <img
                  src={characterNFT.imageURI.replace(
                    "ipfs://",
                    "https://ipfs.io/ipfs/"
                  )}
                  alt={`Character ${characterNFT.name}`}
                />
                <div className="health-bar">
                  <progress value={characterNFT.hp} max={characterNFT.maxHp} />
                  <p>{`${characterNFT.hp} / ${characterNFT.maxHp} HP`}</p>
                </div>
              </div>
              <div className="stats">
                <h4>{`⚔️ Attack Damage: ${characterNFT.attackDamage}`}</h4>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Arena;
