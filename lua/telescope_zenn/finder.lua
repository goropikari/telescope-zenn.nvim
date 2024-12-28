local finders = require('telescope.finders')
local entry_display = require('telescope.pickers.entry_display')
local yaml = require('yaml')

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

---@class Article
---@field title string
---@field emoji string
---@field type string
---@field topics string[]
---@field published boolean
---@field path string

---@return Article[]
local function list_articles()
  local res = vim
    .system({
      'rg',
      '-N',
      '-U',
      '--multiline-dotall',
      '-r',
      '$1',
      '--',
      '^---$\n(.*)\n^---$',
    }, { text = true })
    :wait()
  local lines = vim.split(res.stdout, '\n')

  local temp = {}
  for _, line in ipairs(lines) do
    local path, elem = string.match(line, '(articles/.*.md):(.*)')
    if path then
      if temp[path] then
        table.insert(temp[path], elem)
      else
        temp[path] = { elem }
      end
    end
  end

  local md = {}
  for path, v in pairs(temp) do
    local y = yaml.eval(vim.fn.join(v, '\n'))
    y.path = path
    table.insert(md, y)
  end

  return md
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
