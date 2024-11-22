# InstanceEx

**Setup instructions**

This module requires the `Full-Api-Dump.json` under itself as a module script called `FullAPIDumpJson`. You can get the latest version's api dump [here](https://github.com/MaximumADHD/Roblox-Client-Tracker/blob/roblox/Full-API-Dump.json), 

**API**

- `InstanceEx.GetProperties(Object: Instance | string)` <div>Returns the properties of the passed instance or class name string.</div>

- `InstanceEx.AreAssetsEqual(Asset1: Instance, Asset2: Instance, Settings: { IgnoredProperties: { string }?, CheckRelativePosition: bool?  }?)` <div>Compares the structural equality of two instances with optional settings, `IgnoredSettings` is an array of properties that will be ignored during comparison and `CheckRelativePosition` will compare the position and orientation of parts relative to their parents</div>

e.g:

```lua
local AreEqualSettings = {
    IgnoredProperties = {
        "Parent",
        "CFrame",
        "Rotation"
    },
    CheckRelativePosition = true
}

for _, OtherAsset in AssetsStore do
    if InstanceEx.AreEqual(Asset, OtherAsset, AreEqualSettings) then
        IsNew = false
        SavedAsset = OtherAsset
        break
    end
end
```
