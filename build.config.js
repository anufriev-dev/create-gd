import { defineBuildConfig } from 'unbuild'
import fs from "node:fs"

const outDir = "dist/out"

export default defineBuildConfig({
  entries: ["dist/index"],
  clean: true,
  failOnWarn: false,
  outDir,
  rollup: {
    inlineDependencies: true,
    esbuild: {
      minify: true
    }
  },
  hooks: {
    "build:done"(ctx) {
      fs.copyFileSync(`${outDir}/index.mjs`,"dist/index.mjs")
      fs.rmSync(outDir, { recursive: true })
    }
  }
})
