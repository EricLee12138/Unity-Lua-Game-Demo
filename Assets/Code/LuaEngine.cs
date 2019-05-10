using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using LuaInterface;
using NaughtyAttributes;

class MyLuaState : LuaState {
    public string where()
    {
        int n = LuaDLL.lua_gettop(L);

        using (CString.Block())
        {
            CString sb = CString.Alloc(256);
            int line = LuaDLL.tolua_where(L, 1);
            string filename = LuaDLL.lua_tostring(L, -1);
            LuaDLL.lua_settop(L, n);
            int offset = filename[0] == '@' ? 1 : 0;

            if (!filename.Contains("."))
            {
                sb.Append('[').Append(filename, offset, filename.Length - offset).Append(".lua:").Append(line).Append("]:");
            }
            else
            {
                sb.Append('[').Append(filename, offset, filename.Length - offset).Append(':').Append(line).Append("]:");
            }
            return sb.ToString();
        }
    }
}

public class LuaEngine : MonoBehaviour {

    public static LuaEngine singleton = null;

    public string scriptFolder = "/";
    public string engineFileName;

    private MyLuaState lua = null;
    private LuaTable engine;

    private LuaFunction func_engine_late_update;
    private LuaFunction func_engine_update;

    public string luaWhere()
    {
        return null != lua ? lua.where() : "";
    }

    public void register(LuaRegister v)
    {
        engine.Call("register", v);
    }

    public void unregister(LuaRegister v)
    {
        engine.Call("unregister", v);
    }

    //--------

    private static void addSearchPath(LuaState lua, string root)
    {
        lua.AddSearchPath(root);
        var sub_pathes = Directory.GetDirectories(root, "*", SearchOption.AllDirectories);
        if (null != sub_pathes && 0 < sub_pathes.Length)
        {
            for (int i = 0; i < sub_pathes.Length; ++i)
            {
                lua.AddSearchPath(sub_pathes[i]);
            }
        }
    }

    //--------

    private void Awake()
    {
        if (null != singleton)
        {
            Destroy(gameObject);
            return;
        }
        singleton = this;

        DontDestroyOnLoad(gameObject);

        if (null == scriptFolder)
        {
            return;
        }
        lua = new MyLuaState();
        lua.Start();
        LuaBinder.Bind(lua);

        addSearchPath(lua, Application.dataPath + scriptFolder);

        lua.DoFile(engineFileName);
       
        engine = lua.GetTable("_Engine");
        func_engine_update = engine.GetLuaFunction("update");
        func_engine_late_update = engine.GetLuaFunction("lateupdate");
    }

    private void Start()
    {
        engine.Call("start");
    }

    private void Update()
    {
        func_engine_update.Call();
    }

    private void LateUpdate() {
        func_engine_late_update.Call();
    }

    private void OnDestroy()
    {
        if (null != func_engine_update)
        {
            func_engine_update.Dispose();
            func_engine_update = null;
        }
        if (null != func_engine_late_update)
        {
            func_engine_late_update.Dispose();
            func_engine_late_update = null;
        }
        if (null != engine)
        {
            engine.Call("shutdown");

            engine.Dispose();
            engine = null;
        }
        if (null != lua)
        {
            lua.Dispose();
            lua = null;
        }
    }
}
