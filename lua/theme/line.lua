local conditions = require("heirline.conditions")
local utils = require("heirline.utils")

local Align = { provider = "%="}
--Heirline: utils.pick_child_on_condition() is deprecated, please use the fallthrough field instead. To retain the same functionality, replace `init = utils.pick_child_on_condition()` with `fallthrough = false`  
    
local Separator = { provider = " " }
local Space = {provider = " "}

local colors = require'kanagawa.colors'.setup({
    terminalColors = true,
    theme = "default"
}) -- wink
require('heirline').load_colors(colors)

local ViMode = 
{
    -- get vim current mode, this information will be required by the provider
    -- and the highlight functions, so we compute it only once per component
    -- evaluation and store it as a component attribute
    init = function(self)
        self.mode = vim.fn.mode(1) -- :h mode()

        -- execute this only once, this is required if you want the ViMode
        -- component to be updated on operator pending mode
        if not self.once then
            vim.api.nvim_create_autocmd("ModeChanged", {command = 'redrawstatus'})
            self.once = true
        end
    end,
    -- Now we define some dictionaries to map the output of mode() to the
    -- corresponding string and color. We can put these into `static` to compute
    -- them at initialisation time.
    static = {
        mode_names = 
		{ -- change the strings if you like it vvvvverbose!
            n = "N",
            no = "N?",
            nov = "N?",
            noV = "N?",
            ["no\22"] = "N?",
            niI = "Ni",
            niR = "Nr",
            niV = "Nv",
            nt = "Nt",
            v = "V",
            vs = "Vs",
            V = "V_",
            Vs = "Vs",
            ["\22"] = "^V",
            ["\22s"] = "^V",
            s = "S",
            S = "S_",
            ["\19"] = "^S",
            i = "I",
            ic = "Ic",
            ix = "Ix",
            R = "R",
            Rc = "Rc",
            Rx = "Rx",
            Rv = "Rv",
            Rvc = "Rv",
            Rvx = "Rv",
            c = "C",
            cv = "Ex",
            r = "...",
            rm = "M",
            ["r?"] = "?",
            ["!"] = "!",
            t = "T",
        },
        mode_colors = {
            n = "green" ,
            i = "green",
            v = "cyan",
            V =  "cyan",
            ["\22"] =  "cyan",
            c =  "orange",
            s =  "purple",
            S =  "purple",
            ["\19"] =  "purple",
            R =  "orange",
            r =  "orange",
            ["!"] =  "red",
            t =  "red",
        }
    },
    -- We can now access the value of mode() that, by now, would have been
    -- computed by `init()` and use it to index our strings dictionary.
    -- note how `static` fields become just regular attributes once the
    -- component is instantiated.
    -- To be extra meticulous, we can also add some vim statusline syntax to
    -- control the padding and make sure our string is always at least 2
    -- characters long. Plus a nice Icon.
    provider = function(self)
        return "%2("..self.mode_names[self.mode].."%)"
    end,
    -- Same goes for the highlight. Now the foreground will change according to the current mode.
    hl = function(self)
        local mode = self.mode:sub(1, 1) -- get only the first mode character
        return { fg = self.mode_colors[mode], bold = true, }
    end,
    -- Re-evaluate the component only on ModeChanged event!
    -- This is not required in any way, but it's there, and it's a small
    -- performance improvement.
    update = 'ModeChanged'
}


local FileFlags = {
    {
      condition = function()
        return vim.bo.modified
      end,
      provider = "[+]",
      hl = { fg = "green" },
    },
    {
      condition = function()
          return not vim.bo.modifiable or vim.bo.readonly
      end,
      provider = "",
      hl = { fg = "orange" },
    },
}


-- (vim.fn.haslocaldir(0) == 1 and "l" or "g") .. " " .. 

local WorkDir = {
  provider = function()
--        local icon =" "
    local cwd = vim.fn.expand('%')
    cwd = vim.fn.fnamemodify(cwd, ":~")
--        return icon .. cwd  --.. trail
  return cwd
  end,
  hl =
  {
    fg = utils.get_highlight("Directory").bg,
  },
}



local DefaultStatusline = 
{
  ViMode, Space, Separator, FileFlags, Space, WorkDir, Space
}

local InactiveStatusline = 
{
  condition = function()
    return not conditions.is_active()
  end,

  Separator, FileName, Align
}


local TerminalStatusline = 
{

  condition = function()
    return conditions.buffer_matches({ buftype = { "terminal" } })
  end,


    -- Quickly add a condition to the ViMode to only show it when buffer is active!
    { condition = conditions.is_active, ViMode, Separator },  TerminalName, Align,
}
local SpecialStatusline = 
{
  condition = function()
    return conditions.buffer_matches({
      buftype = { "nofile", "prompt", "help", "quickfix" },
      filetype = { "^git.*", "fugitive" },
    })
  end,

     Separator, HelpFileName, Align
}

local StatusLines = 
{
  SpecialStatusline, TerminalStatusline, InactiveStatusline, DefaultStatusline,
	fallthrough = false,
}
require("heirline").setup(StatusLines)
