local finders = require('telescope.finders')
local entry_display = require('telescope.pickers.entry_display')
local front_matter = require('front-matter')

local M = {}

local entry_maker = function(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = opts.slug_display_length },
      { width = 2 },
      { remaining = true },
    },
  })

  ---@class Entry
  ---@field value Article

  ---@param entry Entry
  local make_display = function(entry)
    local metadata = entry.value
    local slug = string.match(metadata.path, 'articles/(.+).md')
    local slug_abbrev = string.sub(slug, 0, opts.slug_display_length)
    return displayer({
      { slug_abbrev, 'TelescopeResultsIdentifier' },
      metadata.emoji,
      metadata.title,
    })
  end

  ---@param metadata Article
  return function(metadata)
    -- local metadata = vim.json.decode(entry)
    return {
      value = metadata,
      -- add topic tags to improve searchability
      ordinal = metadata.path .. ' ' .. metadata.title .. ' ' .. table.concat(metadata.topics, ' '),
      display = make_display,
      path = metadata.path,
    }
  end
end

local function list_files(directory)
  local files = {}

  -- Check if the directory exists
  if not vim.uv.fs_stat(directory) then
    vim.notify(string.format("Directory '%s' does not exist", directory), vim.log.levels.ERROR)
    return files
  end

  local handle = vim.uv.fs_scandir(directory)
  if not handle then
    vim.notify(string.format("Failed to open directory '%s'", directory), vim.log.levels.ERROR)
    return files
  end

  while true do
    local name, type = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end

    -- Include only files (skip directories if needed)
    if type == 'file' then
      table.insert(files, vim.fs.joinpath(directory, name))
    end
  end

  return files
end

---@class Article
---@field title string
---@field emoji string
---@field type string
---@field topics string[]
---@field published boolean
---@field path string

---@return Article[]
local function list_articles()
  local base_path
  local out = vim.system({ 'git', 'rev-parse', '--show-toplevel' }):wait()
  if out.code == 0 then
    base_path = vim.fn.trim(out.stdout)
  else
    base_path = vim.fn.getcwd()
  end

  local files = list_files(vim.fs.joinpath(base_path, 'articles'))

  local md = front_matter.get(files) or {}
  local metadata = {}
  for k, v in pairs(md) do
    v.path = k
    table.insert(metadata, v)
  end
  return metadata
end

M.make_finder = function(opts)
  local articles = list_articles()

  return finders.new_table({
    results = articles,
    entry_maker = entry_maker(opts),
  })
end

-- M.make_finder = function(opts)
--   return finders.new_table({
--     results = {
--       { color = 'red', rgb = '#ff0000', path = '/tmp/hoge.txt' },
--       { color = 'green', rgb = '#00ff00', path = '/tmp/hoge.txt' },
--       { color = 'blue', rgb = '#0000ff', path = '/tmp/hoge.txt' },
--     },
--     entry_maker = function(entry)
--       return {
--         value = entry,
--         display = entry.color,
--         ordinal = entry.rgb,
--         path = entry.path,
--       }
--     end,
--   })
-- end

return M
