-- (Crudely) Locates the bibliography

local M = {}

M.quarto = {}
M.tex = {}
M['quarto.cached_bib'] = nil

M.locate_quarto_bib = function()
  if M['quarto.cached_bib'] then
    return M['quarto.cached_bib']
  end
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local location = string.match(line, [[bibliography:[ "']*(.+)["' ]*]])
    if location then
      M['quarto.cached_bib'] = location
      return M['quarto.cached_bib']
    end
  end
  -- no bib locally defined
  -- test for quarto project-wide definition
  local fname = vim.api.nvim_buf_get_name(0)
  local root = require('lspconfig.util').root_pattern '_quarto.yml'(fname)
  if root then
    local file = root .. '/_quarto.yml'
    for line in io.lines(file) do
      local location = string.match(line, [[bibliography:[ "']*(.+)["' ]*]])
      if location then
        M['quarto.cached_bib'] = location
        return M['quarto.cached_bib']
      end
    end
  end
end

M.locate_tex_bib = function()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  for _, line in ipairs(lines) do
    local location = string.match(line, [[\bibliography{[ "']*([^'"\{\}]+)["' ]*}]])
    if location then
      return location .. '.bib'
    end
  end
end

M.entry_to_bib_entry = function(entry)
  local bib_entry = '@'
  local item = entry.value
  local citekey = item.citekey
  if not citekey then
    citekey = item.citekey
  end
  bib_entry = bib_entry .. item.itemType .. '{' .. citekey .. ',\n'
  for k, v in pairs(item) do
    if k == 'creators' then
      bib_entry = bib_entry .. '  author = {'
      local author = ''
      for _, creator in ipairs(v) do
        author = author .. creator.lastName .. ', ' .. creator.firstName .. ' and '
      end
      -- remove trailing ' and '
      author = string.sub(author, 1, -6)
      bib_entry = bib_entry .. author .. '},\n'
    elseif k == 'citekey' then
      -- do nothing
      -- already in the header
    elseif k == 'itemType' then
      -- do nothing
      -- already in the header
    else
      bib_entry = bib_entry .. '  ' .. k .. ' = {' .. v .. '},\n'
    end
  end
  bib_entry = bib_entry .. '}\n'
  return bib_entry
end

return M
