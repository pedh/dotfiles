return {
  --- Widen edgy's right edgebar so the Claude Code panel isn't squeezed to 30 columns
  {
    "folke/edgy.nvim",
    opts = {
      options = {
        right = { size = 0.35 }, -- 35% of editor width (values < 1 are treated as fractions)
      },
    },
  },
  --- Configure dashboard-nvim
  {
    "folke/snacks.nvim",
    opts = function(_, options)
      local logo = "\n\n\n\n" .. [[
                 ######      ###        
                   #####      ####      
  ######             ####      ##       
    #####             ###########       
    ########## ###  ############        
  ############ ############             
#######         ####    ###             
       ######   ####     ###  ###       
   #######      ############  ####      
     ### ####   #################       
    ########    ####   ###  ####        
    ####   ##   ####   ###  ####     #  
     #  ####### #### ##### ######   ##  
   ####### #### ###  #######   ### #### 
  ######   ### ##               ####### 
   ###########                   ###### 
    #####                          #####
      ]] .. "\n\n"
      options.dashboard.preset.header = logo
    end,
  },
}
