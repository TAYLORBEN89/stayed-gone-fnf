-- Shared module (replicated to client + server)
local Hello = {}

Hello.GameName = "Stayed Gone"
Hello.Tagline = "Vox vs Alastor"

function Hello.greet(name: string): string
	return `[{Hello.GameName}] Welcome, {name}!`
end

return Hello
