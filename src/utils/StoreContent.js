import {Web3Storage} from "web3.storage";

const web3storage_key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJkaWQ6ZXRocjoweDZkRjQ3NTQ1M0NlZTUwMjMxY0U4MmNmNkU1NEMzQjQzYTE2OEU2ZjMiLCJpc3MiOiJ3ZWIzLXN0b3JhZ2UiLCJpYXQiOjE2NzU5NTMzNzg4MjUsIm5hbWUiOiJob21lIn0.Ttgz826cYMIsMTbGbjxxtgqrLODw9j7epX9C1ze-5HU";

function GetAccessToken() {
    return web3storage_key;
}

function MakeStorageClient() {
    return new Web3Storage({token: GetAccessToken()});
}

export const StoreContent = async (files) => {
    const client = MakeStorageClient();
    return await client.put([files]);
};
