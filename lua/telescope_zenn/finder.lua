local finders = require('telescope.finders')
local entry_display = require('telescope.pickers.entry_display')
local config = require('telescope_zenn.config')

local M = {}

local entry_maker = function(opts)
  local displayer = entry_display.create({
    separator = ' ',
    items = {
      { width = opts.slug_display_length },
      { remaining = true },
    },
  })

  local make_display = function(entry)
    local metadata = entry.value
    local slug = string.match(metadata.path, 'articles/(.+).md')
    local slug_abbrev = string.sub(slug, 0, opts.slug_display_length)
    return displayer({
      { slug_abbrev, 'TelescopeResultsIdentifier' },
      metadata.title,
    })
  end

  return function(entry)
    local metadata = vim.json.decode(entry)
    return {
      value = metadata,
      -- add topic tags to improve searchability
      ordinal = metadata.path,
      display = make_display,
      path = metadata.path,
    }
  end
end

M.make_finder = function(opts)
  opts.entry_maker = entry_maker(config)
  return setmetatable({
    close = function(self)
      self._finder = nil
    end,
  }, {
    __call = function(self, ...)
      -- local cmd = { 'npx', 'zenn', 'list:articles', '--format', 'json' }
      local cmd = {
        'bash',
        '-c',
        [[rg "title: (.+)" --json | jq -c 'select(.type == "match") | {path: .data.path.text, title: .data.lines.text} | .title |= capture("title: \\\"(?<content>.+)\\\"").content']],
      }
      self._finder = finders.new_oneshot_job(cmd, opts)
      self._finder(...)
    end,
  })
end

return M
