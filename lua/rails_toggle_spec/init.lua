-- rails_toggle_spec.lua
-- A Neovim plugin to easily switch between Rails implementation files and their specs

local M = {}

-- Helper function to determine file type based on its path
local function get_file_type(file_path)
	if file_path:match("_spec%.rb$") then
		return "spec"
	elseif file_path:match("%.rb$") then
		return "implementation"
	else
		return "unknown"
	end
end

-- Convert a spec path to an implementation path
local function spec_to_implementation(spec_path)
	-- Remove the '_spec.rb' suffix
	local impl_path = spec_path:gsub("_spec%.rb$", ".rb")

	-- Handle different spec directories
	impl_path = impl_path:gsub("^spec/", "")

	-- Handle request specs (add _controller if missing)
	if impl_path:match("^requests/") then
		impl_path = impl_path:gsub("^requests/", "app/controllers/")
		-- Add _controller suffix if it's not already there
		if not impl_path:match("_controller%.rb$") then
			impl_path = impl_path:gsub("%.rb$", "_controller.rb")
		end
		return impl_path
	end

	-- Handle feature specs (add _controller if missing)
	if impl_path:match("^features/") then
		impl_path = impl_path:gsub("^features/", "app/controllers/")
		-- Add _controller suffix if it's not already there
		if not impl_path:match("_controller%.rb$") then
			impl_path = impl_path:gsub("%.rb$", "_controller.rb")
		end
		return impl_path
	end

	-- Map common Rails directories
	impl_path = impl_path
		:gsub("^controllers/", "app/controllers/")
		:gsub("^models/", "app/models/")
		:gsub("^helpers/", "app/helpers/")
		:gsub("^mailers/", "app/mailers/")
		:gsub("^jobs/", "app/jobs/")
		:gsub("^services/", "app/services/")
		:gsub("^lib/", "lib/")

	return impl_path
end

-- Convert an implementation path to a spec path
local function implementation_to_spec(impl_path)
	local spec_path = impl_path

	-- Handle app/ directory
	spec_path = spec_path:gsub("^app/", "")

	-- Add spec directory prefix and change extension
	if spec_path:match("^controllers/") then
		-- Controllers can have both controller specs and request specs
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	elseif spec_path:match("^models/") then
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	elseif spec_path:match("^helpers/") then
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	elseif spec_path:match("^mailers/") then
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	elseif spec_path:match("^jobs/") then
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	elseif spec_path:match("^services/") then
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	elseif spec_path:match("^lib/") then
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	else
		-- Default fallback
		return "spec/" .. spec_path:gsub("%.rb$", "_spec.rb")
	end
end

-- Try to find the corresponding file
function M.find_corresponding_file()
	local current_file = vim.fn.expand("%:p")
	local file_type = get_file_type(current_file)
	local corresponding_file

	-- Get relative path for the project
	local project_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		project_root = vim.fn.getcwd()
	end

	local relative_path = current_file:gsub(project_root .. "/", "")

	-- Find corresponding file based on file type
	if file_type == "spec" then
		corresponding_file = spec_to_implementation(relative_path)
	elseif file_type == "implementation" then
		corresponding_file = implementation_to_spec(relative_path)
	else
		print("Not a Ruby file or spec file")
		return
	end

	-- Check if the file exists
	local full_path = project_root .. "/" .. corresponding_file
	if vim.fn.filereadable(full_path) == 1 then
		vim.cmd("edit " .. full_path)
	else
		-- Try some alternate locations
		local alternatives = {}

		if file_type == "implementation" and relative_path:match("^app/controllers/") then
			-- Try request specs for controllers (removing "_controller" suffix)
			table.insert(
				alternatives,
				project_root
					.. "/spec/requests/"
					.. relative_path:gsub("^app/controllers/", ""):gsub("_controller%.rb$", "_spec.rb")
			)

			-- Try request specs with controller in the name (less common)
			table.insert(
				alternatives,
				project_root
					.. "/spec/requests/"
					.. relative_path:gsub("^app/controllers/", ""):gsub("%.rb$", "_spec.rb")
			)

			-- Try integration/feature specs (removing "_controller" suffix)
			table.insert(
				alternatives,
				project_root
					.. "/spec/features/"
					.. relative_path:gsub("^app/controllers/", ""):gsub("_controller%.rb$", "_spec.rb")
			)

			-- Try feature specs with controller in the name (less common)
			table.insert(
				alternatives,
				project_root
					.. "/spec/features/"
					.. relative_path:gsub("^app/controllers/", ""):gsub("%.rb$", "_spec.rb")
			)
		end

		local found = false
		for _, alt_path in ipairs(alternatives) do
			if vim.fn.filereadable(alt_path) == 1 then
				vim.cmd("edit " .. alt_path)
				found = true
				break
			end
		end

		if not found then
			print("Corresponding file not found: " .. corresponding_file)

			-- Offer to create the spec file if going from implementation to spec
			if file_type == "implementation" then
				local create_spec = vim.fn.input("Create spec file? (y/n): ")
				if create_spec:lower() == "y" then
					-- Create parent directories if needed
					local spec_dir = vim.fn.fnamemodify(full_path, ":h")
					vim.fn.system("mkdir -p " .. spec_dir)
					vim.cmd("edit " .. full_path)

					-- Add a basic spec template
					local file_basename = vim.fn.fnamemodify(relative_path, ":t:r")
					local spec_template = {
						"require 'rails_helper'",
						"",
						"RSpec.describe " .. file_basename:gsub("^%l", string.upper) .. " do",
						"  # Add your specs here",
						"end",
						"",
					}
					vim.api.nvim_buf_set_lines(0, 0, 0, false, spec_template)
					vim.cmd("write")
				end
			end
		end
	end
end

-- Setup function to be called by the user
function M.setup(opts)
	opts = opts or {}

	-- Create the user command to toggle between files
	vim.api.nvim_create_user_command("RailsToggleSpec", function()
		M.find_corresponding_file()
	end, {})

	-- Create suggested keymapping if not disabled
	if opts.create_mappings ~= false then
		-- Map <Leader>s to toggle between implementation and spec
		vim.api.nvim_set_keymap("n", "<Leader>s", ":RailsToggleSpec<CR>", { noremap = true, silent = true })
	end
end

return M
