import { defineBuilderConfig, githubRepoSyncPlugin } from "@afilmory/builder";

export default defineBuilderConfig(() => ({
  plugins: [
    // Use remote repository as manifest and thumbnail cache
    // githubRepoSyncPlugin({
    //   repo: {
    //     url: 'https://github.com/xxx/xxx',
    //     token: '',
    //     branch: 'main',
    //   },
    // }),
  ],
  storage: {
    // Storage configuration
    provider: "s3",
    bucket: process.env.S3_BUCKET,
    region: "auto",
    prefix: "",
    accessKeyId: process.env.S3_ACCESS_KEY_ID,
    secretAccessKey: process.env.S3_SECRET_ACCESS_KEY,
    customDomain: process.env.S3_CUSTOM_DOMAIN,
    endpoint: process.env.S3_ENDPOINT,
    excludeRegex: /^\.afilmory/,
  },
}));
