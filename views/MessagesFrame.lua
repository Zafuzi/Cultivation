--- TODO: Change this to return a function called AddMessage then makes a new toast
--- MessageFrame should just be the manager of toasts
local Messages = {}

MessagesFrame = OpenModal("MessagesFrame", 300, 50, UIParent, {
	isScrollable = false,
	hasBackdrop = true,
	hasBorder = true,
});
MessagesFrame:SetClampedToScreen(false)

MessagesFrame:SetPoint("TOP", UIParent, "TOP", 0, -50)

MessagesFrame.content = MessagesFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")

MessagesFrame.opacity = 1
MessagesFrame.x = 0
MessagesFrame.y = 0

MessagesFrame:SetScript("OnUpdate", function(self, elapsed)
	local s = ""

	for i, msg in next, Messages, nil do
		s = s .. msg.color .. Dump(msg.content) .. "|r\n"
	end

	if s ~= "" and self.y > -10 then
		self.y = self.y - (500 * elapsed)
	end

	if s == "" and self.y - self:GetHeight() < 0 then
		self.y = self.y + (500 * elapsed)
	end

	self.content:SetText(s)

	self.opacity = Clamp(self.opacity, 0, 1)
	self.y = Clamp(self.y, -50, self:GetHeight())
	self:SetPoint("TOP", UIParent, "TOP", self.x, self.y)
	MessagesFrame:SetAlpha(self.opacity)
end)

MessagesFrame.addMessage = function(self, msg, timeout, color)
	local index = table.insert(Messages, {
		content = msg, color = color or COLORS.ADDON
	})
	self:updateHeight()

	C_Timer.After(timeout or 5, function()
		-- find index again
		table.remove(Messages, index)

		self:updateHeight()
	end)
end

MessagesFrame.updateHeight = function(self)
	self:SetHeight(((#Messages) * 13) + 50)
	self.content:SetPoint("TOPLEFT", self, "TOPLEFT", 10, -10)
	self.content:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -10, 10)
end

MessagesFrame:Show()
