local context = require("drover.context")

describe("drover.context", function()
	local tmpdir
	local cwd_before

	before_each(function()
		tmpdir = vim.fn.tempname()
		vim.fn.mkdir(tmpdir, "p")
		cwd_before = vim.fn.getcwd()
		vim.cmd.cd(tmpdir)
	end)

	after_each(function()
		vim.cmd("silent! %bwipeout!")
		vim.cmd.cd(cwd_before)
		vim.fn.delete(tmpdir, "rf")
	end)

	local function write_file(relpath, lines)
		local abspath = tmpdir .. "/" .. relpath
		vim.fn.writefile(lines, abspath)
		return abspath
	end

	describe("current_file", function()
		it("returns an @-prefixed path relative to cwd", function()
			local abspath = write_file("foo.txt", { "hello" })
			vim.cmd.edit(abspath)
			assert.equals("@foo.txt", context.current_file())
		end)

		it("returns nil for an unnamed buffer", function()
			vim.cmd.enew()
			assert.is_nil(context.current_file())
		end)
	end)

	describe("open_buffers", function()
		it("lists all buflisted file buffers as @-prefixed paths", function()
			vim.fn.mkdir(tmpdir .. "/sub", "p")
			local a = write_file("a.txt", { "a" })
			local b = write_file("sub/b.txt", { "b" })
			vim.cmd.edit(a)
			vim.cmd.edit(b)
			local result = context.open_buffers()
			assert.is_not_nil(result)
			assert.is_true(result:find("@a.txt", 1, true) ~= nil)
			assert.is_true(result:find("@sub/b.txt", 1, true) ~= nil)
		end)

		it("returns nil when there are no file buffers", function()
			vim.cmd("silent! %bwipeout!")
			vim.cmd.enew()
			assert.is_nil(context.open_buffers())
		end)
	end)
end)
