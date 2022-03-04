import path from "path";

import { 
	emulator,
	init,
	getAccountAddress,
	shallPass,
	shallResolve,
	shallRevert,
} from "flow-js-testing";

import { getSherpaAdminAddress } from "../src/common";
import {
	deploySherpaItems,
	getSherpaItemCount,
	getSherpaItemSupply,
	mintSherpaItem,
	setupSherpaItemsOnAccount,
	transferSherpaItem,
	types,
	rarities,
} from "../src/sherpa-items";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(50000);

describe("Sherpa Items", () => {
	// Instantiate emulator and path to Cadence files
	beforeEach(async () => {
		const basePath = path.resolve(__dirname, "../../");
		const port = 7002;
		await init(basePath, { port });
		await emulator.start(port, false);
		return await new Promise(r => setTimeout(r, 1000));
	});

	// Stop emulator, so it could be restarted
	afterEach(async () => {
		await emulator.stop();
		return await new Promise(r => setTimeout(r, 1000));
	});

	it("should deploy SherpaItems contract", async () => {
		await deploySherpaItems();
	});

	it("supply should be 0 after contract is deployed", async () => {
		// Setup
		await deploySherpaItems();
		const SherpaAdmin = await getSherpaAdminAddress();
		await shallPass(setupSherpaItemsOnAccount(SherpaAdmin));

		await shallResolve(async () => {
			const supply = await getSherpaItemSupply();
			expect(supply).toBe(0);
		});
	});

	it("should be able to mint a sherpa item", async () => {
		// Setup
		await deploySherpaItems();
		const Alice = await getAccountAddress("Alice");
		await setupSherpaItemsOnAccount(Alice);

		// Mint instruction for Alice account shall be resolved
		await shallPass(mintSherpaItem(Alice, types.membership, rarities.standard));
	});

	it("should be able to create a new empty NFT Collection", async () => {
		// Setup
		await deploySherpaItems();
		const Alice = await getAccountAddress("Alice");
		await setupSherpaItemsOnAccount(Alice);

		// shall be able te read Alice collection and ensure it's empty
		await shallResolve(async () => {
			const itemCount = await getSherpaItemCount(Alice);
			expect(itemCount).toBe(0);
		});
	});

	it("should not be able to withdraw an NFT that doesn't exist in a collection", async () => {
		// Setup
		await deploySherpaItems();
		const Alice = await getAccountAddress("Alice");
		const Bob = await getAccountAddress("Bob");
		await setupSherpaItemsOnAccount(Alice);
		await setupSherpaItemsOnAccount(Bob);

		// Transfer transaction shall fail for non-existent item
		await shallRevert(transferSherpaItem(Alice, Bob, 1337));
	});

	it("should be able to withdraw an NFT and deposit to another accounts collection", async () => {
		await deploySherpaItems();
		const Alice = await getAccountAddress("Alice");
		const Bob = await getAccountAddress("Bob");
		await setupSherpaItemsOnAccount(Alice);
		await setupSherpaItemsOnAccount(Bob);

		// Mint instruction for Alice account shall be resolved
		await shallPass(mintSherpaItem(Alice, types.membership, rarities.standard));

		// Transfer transaction shall pass
		await shallPass(transferSherpaItem(Alice, Bob, 0));
	});
});
