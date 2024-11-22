local HttpService = game:GetService("HttpService")

local API = HttpService:JSONDecode(require(script:WaitForChild("FullAPIDumpJson")))

local FormattedAPI = {}

local function GetClassFromName(ClassName)
	for i, Class in API.Classes do 
		if Class.Name == ClassName then
			return Class 
		end
	end
end

local UnavailableContexts = {
	"RobloxScriptSecurity",
	"RobloxSecurity",
	"LocalUserSecurity",
	"PluginSecurity"
}

local UnreadableTags = { 
	"ReadOnly",
	"Hidden",
	"NotScriptable"
}

local function GatherProperties(ClassName, AccumulatedProperties)
	local Class = GetClassFromName(ClassName)

	if not Class then
		return AccumulatedProperties
	end

	if Class.Members then
		for _, Member in Class.Members do
			if Member.MemberType == "Property" then
				local IsRealProperty = true

				if Member.Tags then
					for i, Tag in Member.Tags do
						if table.find(UnreadableTags, Tag) then
							IsRealProperty = false
							break
						end
					end
				end

				if Member.Security and Member.Security.Read and table.find(UnavailableContexts, Member.Security.Read) then
					IsRealProperty = false
				end

				if IsRealProperty then
					if not table.find(AccumulatedProperties, Member.Name) then
						table.insert(AccumulatedProperties, Member.Name)
					end
				end
			end
		end
	end

	if Class.Superclass then
		return GatherProperties(Class.Superclass, AccumulatedProperties)
	end

	return AccumulatedProperties
end

for _, Class in API.Classes do
	local Properties = GatherProperties(Class.Name, {})

	FormattedAPI[Class.Name] = Properties
end

local InstanceEx = {}

function InstanceEx.GetProperties(Object)
	if type(Object) == "string" then
		return table.clone(FormattedAPI[Object.ClassName])
	end

	return table.clone(FormattedAPI[Object.ClassName])
end

local function GetPivot(Object)
	if Object:IsA("Model") then
		return Object:GetPivot()
	elseif Object:IsA("BasePart") then
		return Object.CFrame
	else
		return nil
	end
end

local function AreCFramesEqual(CFrame1, CFrame2, Tolerance)
	Tolerance = Tolerance or 1e-5

	local Position1 = CFrame1.Position
	local Position2 = CFrame2.Position

	if (Position1 - Position2).Magnitude > Tolerance then
		return false
	end

	local _, _, _, r11_1, r12_1, r13_1, r21_1, r22_1, r23_1, r31_1, r32_1, r33_1 = CFrame1:GetComponents()
	local _, _, _, r11_2, r12_2, r13_2, r21_2, r22_2, r23_2, r31_2, r32_2, r33_2 = CFrame2:GetComponents()

	local RotationEqual = math.abs(r11_1 - r11_2) < Tolerance and
		math.abs(r12_1 - r12_2) < Tolerance and
		math.abs(r13_1 - r13_2) < Tolerance and
		math.abs(r21_1 - r21_2) < Tolerance and
		math.abs(r22_1 - r22_2) < Tolerance and
		math.abs(r23_1 - r23_2) < Tolerance and
		math.abs(r31_1 - r31_2) < Tolerance and
		math.abs(r32_1 - r32_2) < Tolerance and
		math.abs(r33_1 - r33_2) < Tolerance

	return RotationEqual
end

local function RemoveProperties(PropertyList, IgnoredProperties)
	for i, Property in IgnoredProperties do 
		local Index = table.find(PropertyList, Property)
		if Index then
			table.remove(PropertyList, Index)
		end
	end
end

local function AreAssetsEqual(Asset1, Asset2, Settings)
	if Asset1.ClassName ~= Asset2.ClassName then
		return false
	end

	local IgnoredProperties = (Settings and Settings.IgnoredProperties) or { }

	local Properties1 = InstanceEx.GetProperties(Asset1)
	local Properties2 = InstanceEx.GetProperties(Asset2)

	RemoveProperties(Properties1, IgnoredProperties)
	RemoveProperties(Properties2, IgnoredProperties)

	for _, Property in Properties1 do
		if not table.find(Properties2, Property) or Asset1[Property] ~= Asset2[Property] then
			return false
		end
	end

	local Children1 = Asset1:GetChildren()
	local Children2 = Asset2:GetChildren()

	if #Children1 ~= #Children2 then
		return false
	end	

	for i, Child1 in Children1 do 
		local MatchedChild = nil 

		for i, Child2 in Children2 do 
			if not AreAssetsEqual(Child1, Child2, Settings) then
				continue
			end

			if Settings and Settings.CheckRelativePosition then
				local ParentPivot1 = GetPivot(Asset1)
				local ParentPivot2 = GetPivot(Asset2)
				local ChildPivot1 = GetPivot(Child1)
				local ChildPivot2 = GetPivot(Child2)

				if ParentPivot1 and ParentPivot2 and ChildPivot1 and ChildPivot2 then
					local RelativeCFrame1 = ParentPivot1:ToObjectSpace(ChildPivot1)
					local RelativeCFrame2 = ParentPivot2:ToObjectSpace(ChildPivot2)

					if not AreCFramesEqual(RelativeCFrame1, RelativeCFrame2) then
						continue
					end
				else
					continue
				end
			end

			MatchedChild = Child2
			break
		end

		if MatchedChild then
			table.remove(Children2, table.find(Children2, MatchedChild))
		else
			return false
		end
	end

	if #Children2 ~= 0 then
		return false
	end

	return true
end

function InstanceEx.AreEqual(Asset1, Asset2, IgnoredProperties)
	return AreAssetsEqual(Asset1, Asset2, IgnoredProperties)	
end

return InstanceEx
