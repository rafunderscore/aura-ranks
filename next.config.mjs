/** @type {import('next').NextConfig} */
const nextConfig = {
  images: {
    domains: ["i.scdn.co", "avatar.vercel.sh", "example.com"],
  },

  sassOptions: {
    includePaths: ["./styles"],
    prependData: `@import "index.scss";`,
  },
};

export default nextConfig;
