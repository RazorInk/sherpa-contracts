import { mintFlow } from "flow-js-testing";
import { 
	sendTransactionWithErrorRaised, 
	executeScriptWithErrorRaised, 
	deployContractByNameWithErrorRaised 
} from "./common"
import { getSherpaAdminAddress } from "./common";

export const types = {
	membership: 1,
	collectable: 2
};

export const rarities = {
	standard: 1,
	special: 2
};



/*
 * Deploys NonFungibleToken and SherpaItems contracts to SherpaAdmin.
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const deploySherpaItems = async () => {
	const SherpaAdmin = await getSherpaAdminAddress();
	await mintFlow(SherpaAdmin, "1000.0");

	await deployContractByNameWithErrorRaised({ to: SherpaAdmin, name: "NonFungibleToken" });

	await deployContractByNameWithErrorRaised({ to: SherpaAdmin, name: "MetadataViews" });

	const addressMap = { 
		NonFungibleToken: SherpaAdmin,
		MetadataViews: SherpaAdmin,
	};
	
	return deployContractByNameWithErrorRaised({ to: SherpaAdmin, name: "SherpaItems", addressMap });
};

/*
 * Setups SherpaItems collection on account and exposes public capability.
 * @param {string} account - account address
 * @throws Will throw an error if transaction is reverted.
 * @returns {Promise<*>}
 * */
export const setupSherpaItemsOnAccount = async (account) => {
	const name = "sherpaItems/setup_account";
	const signers = [account];

	return sendTransactionWithErrorRaised({ name, signers });
};

/*
 * Returns SherpaItems supply.
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64} - number of NFT minted so far
 * */
export const getSherpaItemSupply = async () => {
	const name = "sherpaItems/get_sherpa_items_supply";

	return executeScriptWithErrorRaised({ name });
};

/*
 * Mints SherpaItem of a specific **itemType** and sends it to **recipient**.
 * @param {UInt64} itemType - type of NFT to mint
 * @param {string} recipient - recipient account address
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const mintSherpaItem = async (recipient, itemType, itemRarity) => {
	const SherpaAdmin = await getSherpaAdminAddress();

	const name = "sherpaItems/mint_sherpa_item";
	const args = [recipient, itemType, itemRarity];
	const signers = [SherpaAdmin];

	return sendTransactionWithErrorRaised({ name, args, signers });
};

/*
 * Transfers SherpaItem NFT with id equal **itemId** from **sender** account to **recipient**.
 * @param {string} sender - sender address
 * @param {string} recipient - recipient address
 * @param {UInt64} itemId - id of the item to transfer
 * @throws Will throw an error if execution will be halted
 * @returns {Promise<*>}
 * */
export const transferSherpaItem = async (sender, recipient, itemId) => {
	const name = "sherpaItems/transfer_sherpa_item";
	const args = [recipient, itemId];
	const signers = [sender];

	return sendTransactionWithErrorRaised({ name, args, signers });
};

/*
 * Returns the SherpaItem NFT with the provided **id** from an account collection.
 * @param {string} account - account address
 * @param {UInt64} itemID - NFT id
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getSherpaItem = async (account, itemID) => {
	const name = "sherpaItems/get_sherpa_item";
	const args = [account, itemID];

	return executeScriptWithErrorRaised({ name, args });
};

/*
 * Returns the number of Sherpa Items in an account's collection.
 * @param {string} account - account address
 * @throws Will throw an error if execution will be halted
 * @returns {UInt64}
 * */
export const getSherpaItemCount = async (account) => {
	const name = "sherpaItems/get_collection_length";
	const args = [account];

	return executeScriptWithErrorRaised({ name, args });
};
