/** @type {import('next').NextConfig} */
const nextConfig = {
    images: {
        domains: ['i.scdn.co'],
    },

    sassOptions: {
        includePaths: ['./styles'],
        prependData: `@import "index.scss";`,
    },
};

export default nextConfig;
