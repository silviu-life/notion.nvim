local M = {}

local status = false
local curl = require('plenary.curl')

--Try a key synchronously
local tryKey = function()
  local l =
    require('notion').readFile(vim.fn.stdpath('data') .. '/notion/data.txt')
  local headers = {}
  headers['Content-Type'] = 'application/json'
  headers['Notion-Version'] = '2021-05-13'
  headers['Authorization'] = 'Bearer ' .. l

  local res = curl.get {
    method = 'POST',
    url = 'https://api.notion.com/v1/search',
    headers = headers,
  }

  if res.status == 401 then
    return false
  end
  vim.print('[Notion] Status: Operational')

  require('notion').writeFile(
    vim.fn.stdpath('data') .. '/notion/prev.txt',
    'true'
  )
  status = true

  vim.schedule(function()
    require('notion').update { silent = false }
  end)
  return true
end

--When a key is not set/invalid
local noKey = function()
  local newKey =
    vim.fn.input('Api key invalid/not set, insert new key:', '', 'file')
  require('notion').writeFile(
    vim.fn.stdpath('data') .. '/notion/data.txt',
    newKey
  )
  if not tryKey() then
    return vim.print('[Notion] Invalid key, please try again')
  end
end

--Function linked to NotionSetup
local notionSetup = function()
  local content =
    require('notion').readFile(vim.fn.stdpath('data') .. '/notion/data.txt')
  if not content or content == '' or content == ' ' then
    if os.getenv('NOTION_API_KEY') then
      require('notion').writeFile(
        vim.fn.stdpath('data') .. '/notion/data.txt',
        os.getenv('NOTION_API_KEY')
      )
      if not tryKey() then
        noKey()
      end
    else
      noKey()
    end
  else
    if not tryKey() then
      noKey()
    end
  end
end

--User accesible function
M.initialisation = function()
  require('notion').fileInit()
  notionSetup()
  return status
end

return M
