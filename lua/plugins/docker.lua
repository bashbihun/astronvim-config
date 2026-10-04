-- lua/plugins/docker.lua
-- Docker & Podman support:
--   1. LSP buat Dockerfile & docker-compose.yml (syntax check, hover, completion)
--   2. Dockyard: UI buat lihat/kelola container, image, network, logs dari
--      dalam nvim (tanpa keluar ke terminal buka `docker ps` manual)
--
-- CATATAN PODMAN:
-- Dockyard (dan kebanyakan tool sejenis) manggil binary bernama `docker`.
-- Kalau kamu full Podman tanpa Docker terinstall, aktifkan podman-docker
-- shim biar command `docker` diarahkan ke `podman`:
--   Arch:   sudo pacman -S podman-docker
--   Fedora: sudo dnf install podman-docker
--   Ubuntu: sudo apt install podman-docker
--   Manual: sudo ln -s /usr/bin/podman /usr/local/bin/docker
-- Setelah itu semua keymap/command di bawah otomatis kepakai buat podman juga.
--
-- Keymap:
--   <leader>Ko  -> buka Dockyard (list container/image/network)
--   <leader>Kf  -> buka Dockyard dalam floating window
return {
  {
    "emrearmagan/dockyard.nvim",
    dependencies = { "akinsho/toggleterm.nvim" },
    cmd = { "Dockyard", "DockyardFloat" },
    opts = {},
  },

  {
    "AstroNvim/astrocore",
    opts = {
      mappings = {
        n = {
          ["<Leader>K"] = { desc = " Docker/Podman" },
          ["<Leader>Ko"] = { "<cmd>Dockyard<CR>", desc = "Open container manager" },
          ["<Leader>Kf"] = { "<cmd>DockyardFloat<CR>", desc = "Open container manager (float)" },
        },
      },
    },
  },

  -- Mason: LSP untuk Dockerfile & docker-compose.yml
  {
    "williamboman/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "dockerfile-language-server",
        "docker-compose-language-service",
      })
      return opts
    end,
  },

  {
    "AstroNvim/astrolsp",
    opts = {
      config = {
        dockerls = {}, -- Dockerfile
        docker_compose_language_service = {}, -- docker-compose.yml / compose.yaml
      },
    },
  },

  -- treesitter parser Dockerfile
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = require("astrocore").list_insert_unique(opts.ensure_installed, {
        "dockerfile",
      })
      return opts
    end,
  },
}