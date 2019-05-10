using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using NaughtyAttributes;

public class LuaRegister : MonoBehaviour {

    [DisableIf("applicationIsPlaying"), Dropdown("type_name_list")]
    public int type;
    [DisableIf("applicationIsPlaying")]
    public int id = 0;

    private DropdownList<int> type_name_list = new DropdownList<int>()
    {
        {"Ground", 1},
        {"AI", 2},
        {"Enemy", 3},
        {"Player", 4},
        {"Coin", 5},
        {"Camera", 6}
    };

    public static bool applicationIsPlaying()
    {
        return Application.isPlaying;
    }

    //--------

    private void Awake()
    {
        Debug.Assert(0 != type);
        Debug.Assert(0 != id);
    }

    private void Start()
    {
        if (null != LuaEngine.singleton)
        {
            LuaEngine.singleton.register(this);
        }
    }

    private void OnDestroy()
    {
        if (null != LuaEngine.singleton)
        {
            LuaEngine.singleton.unregister(this);
        }
    }
}
