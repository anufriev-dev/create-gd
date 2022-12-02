import prompts from 'prompts'
import fs from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import {
  red,
  cyan,
  yellow
} from 'kolorist'

cwd = do process.cwd


multicore = [
  {
    title: 'Esbuild'
    value: 'esbuild'
    color: yellow
    templates: [
      {
        title: 'react-coffee'
        value: 'react-coffee'
        color: cyan
      }
    ]
  }
]

init= ->
  try
    response = await prompts [
      {
        type: 'text'
        name: 'pkgNameDir'
        initial: 'my-app'
        message: 'Project name:'
        validate: (name) => /^(?:@[a-z\d\-*~][a-z\d\-*._~]*\/)?[a-z\d\-~][a-z\d\-._~]*$/.test name
      }
      {
        type: (pkgNameDir) =>
          if fs.existsSync( path.join cwd, pkgNameDir ) then 'confirm' else null
        message: (pkgNameDir) => "Dir: \"#{pkgNameDir}\" already exist. Overwrite and continue?"
      }
      {
        type: (isOverwrite) =>
          if isOverwrite then null else throw new Error
      }
      {
        type: 'select'
        name: 'core'
        message: 'Select a core'
        choices: multicore.map ({ title, value, color }) => { title: color(title), value }
      }
      {
        type: true && "select"
        name: 'template'
        message: 'Select a template'
        choices:(value) =>
          [core] = multicore.filter (c) => c.value is value
          core.templates.map ({ title, value, color }) =>
            { title: color(title), value }
      }
    ], {
      onCancel: ->
        throw new Error
    }
  catch
    console.log red('✖') + ' Operation cancelled'

  # user choice
  { pkgNameDir, core, template } = response
  # target dir
  root = path.join cwd, pkgNameDir

  # make dir
  if fs.existsSync root then fs.rmSync root , recursive: yes
  fs.mkdirSync root

  templateDir = path.resolve fileURLToPath(import.meta.url),
    '../..'
    'templates'
    core
    template

  # copy files
  copyDir = (srcDir, destDir) =>
    fs.mkdirSync destDir, recursive: yes
    for file in fs.readdirSync srcDir
      srcFile = path.resolve srcDir, file
      destFile = path.resolve destDir, file
      copy srcFile, destFile

  copy = (src, dest) =>
    stat = fs.statSync src
    if do stat.isDirectory
      copyDir src, dest
    else
      fs.copyFileSync src, dest

  copy templateDir, pkgNameDir

  # parse package.json
  pkgParse = (file, name) =>
    pkg = JSON.parse(file)
    pkg.name = name
    pkg.version = "0.0.0"
    delete pkg.author
    delete pkg.repository
    return JSON.stringify pkg, null, 2

  pkgPath = path.join root, "package.json"
  pkgFile = fs.readFileSync pkgPath
  pkg = pkgParse pkgFile, pkgNameDir
  # rewrite package.json
  fs.writeFileSync pkgPath, pkg

  # logs
  console.log '\nDone. Now run:\n'

  pkgManager = process.env.npm_config_user_agent?.split("/")?[0] ? "npm"

  console.log "  cd #{path.basename root}"
  console.log "  #{pkgManager} install"
  console.log "  #{pkgManager} run dev\n"


init().catch => do process.exit 0
