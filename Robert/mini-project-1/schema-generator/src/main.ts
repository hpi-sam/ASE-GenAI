import { StoreController } from './store.controller';

const main = async () => {
	// Wait for DB to be prepared
	await new Promise((resolve) => setTimeout(resolve, 5000));
	// Prepare DB schema.
	new StoreController();
};

main();
