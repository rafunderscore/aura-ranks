/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: [
      "i.scdn.co",
      "avatar.vercel.sh",
      "api.dicebear.com",
      "example.com",
      "avatars.githubusercontent.com",
      "cloudflare-ipfs.com",
    ],
  },
  sassOptions: {
    includePaths: ["./styles"],
    prependData: `@import "index.scss";`,
  },
};

export default nextConfig;
