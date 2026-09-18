/** @type {import('next').NextConfig} */
const nextConfig = {
  // Static export: `next build` writes plain HTML to out/, so the site can be
  // hosted anywhere and every page is crawlable without running JavaScript.
  output: 'export',
  trailingSlash: true,
  images: { unoptimized: true },
  reactStrictMode: true,
};

export default nextConfig;
