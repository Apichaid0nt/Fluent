local TweenService = game:GetService("TweenService")
local Root = script.Parent.Parent
local Flipper = require(Root.Packages.Flipper)
local Creator = require(Root.Creator)

local New = Creator.New
local Spring = Flipper.Spring.new
local Instant = Flipper.Instant.new
local Components = Root.Components

local TabModule = {
	Window = nil,
	Tabs = {},
	Containers = {},
	SelectedTab = 0,
	TabCount = 0,
}

function TabModule:Init(Window)
	TabModule.Window = Window
	return TabModule
end

function TabModule:GetCurrentTabPos()
	local TabHolderPos = TabModule.Window.TabHolder.AbsolutePosition.Y
	local TabPos = TabModule.Tabs[TabModule.SelectedTab].Frame.AbsolutePosition.Y

	return TabPos - TabHolderPos
end

function TabModule:New(Title, Icon, Parent)
	local Library = require(Root)
	local Window = TabModule.Window
	local Elements = Library.Elements

	TabModule.TabCount = TabModule.TabCount + 1
	local TabIndex = TabModule.TabCount

	local Tab = {
		Selected = false,
		Name = Title,
		Type = "Tab",
	}

	if Library:GetIcon(Icon) then
		Icon = Library:GetIcon(Icon)
	end

	if Icon == "" or nil then
		Icon = nil
	end

	Tab.Frame = New("TextButton", {
		Size = UDim2.new(1, 0, 0, 34),
		BackgroundTransparency = 1,
		Parent = Parent,
		ThemeTag = {
			BackgroundColor3 = "Tab",
		},
	}, {
		New("UICorner", {
			CornerRadius = UDim.new(0, 6),
		}),
		New("TextLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = Icon and UDim2.new(0, 30, 0.5, 0) or UDim2.new(0, 12, 0.5, 0),
			Text = Title,
			RichText = true,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0,
			FontFace = Font.new(
				"rbxasset://fonts/families/GothamSSm.json",
				Enum.FontWeight.Regular,
				Enum.FontStyle.Normal
			),
			TextSize = 12,
			TextXAlignment = "Left",
			TextYAlignment = "Center",
			Size = UDim2.new(1, -12, 1, 0),
			BackgroundTransparency = 1,
			ThemeTag = {
				TextColor3 = "Text",
			},
		}),
		New("ImageLabel", {
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 8, 0.5, 0),
			BackgroundTransparency = 1,
			Image = Icon and Icon or nil,
			ThemeTag = {
				ImageColor3 = "Text",
			},
		}),
	})

	local ContainerLayout = New("UIListLayout", {
		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Tab.ContainerFrame = New("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Parent = Window.ContainerHolder,
		Visible = false,
		BottomImage = "rbxassetid://6889812791",
		MidImage = "rbxassetid://6889812721",
		TopImage = "rbxassetid://6276641225",
		ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255),
		ScrollBarImageTransparency = 0.95,
		ScrollBarThickness = 3,
		BorderSizePixel = 0,
		CanvasSize = UDim2.fromScale(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, {
		ContainerLayout,
		New("UIPadding", {
			PaddingRight = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 1),
			PaddingTop = UDim.new(0, 1),
			PaddingBottom = UDim.new(0, 1),
		}),
	})

	Creator.AddSignal(ContainerLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		Tab.ContainerFrame.CanvasSize = UDim2.new(0, 0, 0, ContainerLayout.AbsoluteContentSize.Y + 2)
	end)

	-- ── Search Bar ──────────────────────────────────────────────────────────
	local SearchBarFrame = New("Frame", {
		Size = UDim2.new(1, -11, 0, 32),
		BackgroundColor3 = Color3.fromRGB(40, 40, 40),
		BackgroundTransparency = 0.4,
		BorderSizePixel = 0,
		LayoutOrder = 0,
		Parent = Tab.ContainerFrame,
		ThemeTag = { BackgroundColor3 = "ElementBackground" },
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		New("UIStroke", {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Transparency = 0.7,
			ThemeTag = { Color = "InElementBorder" },
		}),
		New("TextLabel", {
			Text = "🔍",
			TextSize = 13,
			Size = UDim2.fromOffset(24, 32),
			Position = UDim2.fromOffset(6, 0),
			BackgroundTransparency = 1,
			ThemeTag = { TextColor3 = "SubText" },
		}),
	})

	local SearchBox = New("TextBox", {
		Size = UDim2.new(1, -36, 1, -8),
		Position = UDim2.fromOffset(30, 4),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		PlaceholderText = "Search...",
		PlaceholderColor3 = Color3.fromRGB(90, 90, 90),
		Text = "",
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClearTextOnFocus = false,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
		Parent = SearchBarFrame,
		ThemeTag = { TextColor3 = "Text" },
	})

	-- highlight border on focus
	local SearchStroke = SearchBarFrame:FindFirstChildWhichIsA("UIStroke")
	SearchBox.Focused:Connect(function()
		if SearchStroke then
			TweenService:Create(SearchStroke, TweenInfo.new(0.2), { Transparency = 0, Color = Color3.fromRGB(76, 194, 255) }):Play()
		end
	end)
	SearchBox.FocusLost:Connect(function()
		if SearchStroke then
			TweenService:Create(SearchStroke, TweenInfo.new(0.2), { Transparency = 0.7 }):Play()
			if SearchStroke then SearchStroke.Color = Color3.new(1,1,1) end
		end
	end)

	-- filter function: hide/show elements and section roots
	local function applySearch(query)
		query = query:lower()
		local isEmpty = query == ""

		for _, child in ipairs(Tab.ContainerFrame:GetChildren()) do
			-- skip layout, padding, search bar itself
			if child == SearchBarFrame
				or child:IsA("UIListLayout")
				or child:IsA("UIPadding")
			then continue end

			-- Section Root: has a TextLabel title + a Container Frame child
			local sectionTitleLabel = child:FindFirstChildWhichIsA("TextLabel")
			local sectionContainer   = child:FindFirstChildOfClass("Frame")

			if sectionTitleLabel and sectionContainer then
				-- it's a section root — check if any element inside matches
				if isEmpty then
					child.Visible = true
					for _, el in ipairs(sectionContainer:GetChildren()) do
						if el:IsA("Frame") then el.Visible = true end
					end
				else
					local sectionHasMatch = false
					for _, el in ipairs(sectionContainer:GetChildren()) do
						if not el:IsA("Frame") then continue end
						local lbl = el:FindFirstChildWhichIsA("TextLabel")
						local title = lbl and lbl.Text:lower() or ""
						local match = title:find(query, 1, true) ~= nil
						el.Visible = match
						if match then sectionHasMatch = true end
					end
					child.Visible = sectionHasMatch
				end
			else
				-- direct element (not in a section)
				if isEmpty then
					child.Visible = true
				else
					local lbl = child:FindFirstChildWhichIsA("TextLabel")
					local title = lbl and lbl.Text:lower() or ""
					child.Visible = title:find(query, 1, true) ~= nil
				end
			end
		end
	end

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		applySearch(SearchBox.Text)
	end)

	Tab.Motor, Tab.SetTransparency = Creator.SpringMotor(1, Tab.Frame, "BackgroundTransparency")

	Creator.AddSignal(Tab.Frame.MouseEnter, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseLeave, function()
		Tab.SetTransparency(Tab.Selected and 0.89 or 1)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Down, function()
		Tab.SetTransparency(0.92)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Up, function()
		Tab.SetTransparency(Tab.Selected and 0.85 or 0.89)
	end)
	Creator.AddSignal(Tab.Frame.MouseButton1Click, function()
		TabModule:SelectTab(TabIndex)
	end)

	TabModule.Containers[TabIndex] = Tab.ContainerFrame
	TabModule.Tabs[TabIndex] = Tab

	Tab.Container = Tab.ContainerFrame
	Tab.ScrollFrame = Tab.Container

	function Tab:AddSection(SectionTitle)
		local Section = { Type = "Section" }

		local SectionFrame = require(Components.Section)(SectionTitle, Tab.Container)
		Section.Container = SectionFrame.Container
		Section.ScrollFrame = Tab.Container

		setmetatable(Section, Elements)
		return Section
	end

	setmetatable(Tab, Elements)
	return Tab
end

function TabModule:SelectTab(Tab)
	local Window = TabModule.Window

	TabModule.SelectedTab = Tab

	for _, TabObject in next, TabModule.Tabs do
		TabObject.SetTransparency(1)
		TabObject.Selected = false
	end
	TabModule.Tabs[Tab].SetTransparency(0.89)
	TabModule.Tabs[Tab].Selected = true

	Window.TabDisplay.Text = TabModule.Tabs[Tab].Name
	Window.SelectorPosMotor:setGoal(Spring(TabModule:GetCurrentTabPos(), { frequency = 6 }))

	task.spawn(function()
		Window.ContainerHolder.Parent = Window.ContainerAnim
		
		Window.ContainerPosMotor:setGoal(Spring(15, { frequency = 10 }))
		Window.ContainerBackMotor:setGoal(Spring(1, { frequency = 10 }))
		task.wait(0.12)
		for _, Container in next, TabModule.Containers do
			Container.Visible = false
		end
		TabModule.Containers[Tab].Visible = true
		Window.ContainerPosMotor:setGoal(Spring(0, { frequency = 5 }))
		Window.ContainerBackMotor:setGoal(Spring(0, { frequency = 8 }))
		task.wait(0.12)
		Window.ContainerHolder.Parent = Window.ContainerCanvas
	end)
end

return TabModule
