package("quickjs")

    set_homepage("https://bellard.org/quickjs/")
    set_description("QuickJS is a small and embeddable Javascript engine")

    add_urls("https://github.com/bellard/quickjs.git")
    add_versions("2021.03.27", "b5e62895c619d4ffc75c9d822c8d85f1ece77e5b")
    add_versions("2023.12.09", "daa35bc1e5d43192098af9b51caeb4f18f73f9f9")
    add_versions("2024.01.13", "d6c7d169de6fb2c90cd2bd2226ba9dafdef883ce")
    
    if is_plat("windows") then
        add_deps("mingw-w64")
        add_patches("2024.01.13", path.join(os.scriptdir(), "patches", "2024.01.13", "msvc.patch"), "4e3b6a346a2b55455cba832d543876daba9f7fce6011ba9f858b2de31f0fd0e8")
        add_configs("shared", {description = "Build shared library.", default = true, type = "boolean", readonly = true})
    end

    if is_plat("linux", "macosx", "iphoneos", "cross") then
        add_syslinks("pthread", "dl", "m")
    elseif is_plat("android") then
        add_syslinks("dl", "m")
    end
    
    on_install("linux", "macosx", "iphoneos", "android", "mingw", "cross", function (package)
        io.writefile("xmake.lua", ([[
            add_rules("mode.debug", "mode.release")
            target("quickjs")
                set_kind("$(kind)")
                add_files("quickjs*.c", "cutils.c", "lib*.c")
                add_headerfiles("quickjs-libc.h")
                add_headerfiles("quickjs.h")
                add_installfiles("*.js", {prefixdir = "share"})
                set_languages("c99")
                add_defines("CONFIG_VERSION=\"%s\"", "_GNU_SOURCE")
                add_defines("CONFIG_BIGNUM")
                if is_plat("windows", "mingw") then
                    add_defines("__USE_MINGW_ANSI_STDIO")
                end
        ]]):format(package:version_str()))
        local configs = {}
        if package:config("shared") then
            configs.kind = "shared"
        end
        if package:is_plat("cross") then
            io.replace("quickjs.c", "#define CONFIG_PRINTF_RNDN", "")
        end
        import("package.tools.xmake").install(package, configs)
    end)

    on_install("windows|x86", "windows|x64", function (package)
        local configs = {}
        io.writefile("xmake.lua", ([[
            add_rules("mode.debug", "mode.release")
            target("quickjs")
                set_kind("shared")
                set_toolchains("mingw")
                add_files("quickjs*.c", "cutils.c", "lib*.c")
                add_headerfiles("quickjs-libc.h")
                add_headerfiles("quickjs.h")
                add_installfiles("*.js", {prefixdir = "share"})
                set_languages("c99")
                add_defines("CONFIG_VERSION=\"%s\"", "_GNU_SOURCE")
                add_defines("CONFIG_BIGNUM","__USE_MINGW_ANSI_STDIO", "__MINGW__COMPILE__")
                set_targetdir("bin")
                add_shflags("-Wl,--output-def,quickjs.def")
                add_syslinks("pthread")
        ]]):format(package:version_str()))
        
        import("package.tools.xmake").install(package, {})
        if is_arch("x64", "x86_64") then
            os.run("lib /Machine:x64 /Def:quickjs.def")
        elseif is_arch("x86") then
            os.run("lib /Machine:x86 /Def:quickjs.def")
        end
        print(os.curdir())
        os.cp(path.join("bin", "quickjs.dll"), package:installdir("bin"))
        os.cp("quickjs.h", package:installdir("include"))
        os.cp("quickjs.lib", path.join(package:installdir("lib"), "quickjs.lib"))
        package:addenv("PATH", "bin")
    end)

    on_test(function (package)
        -- assert(package:has_cfuncs("JS_NewRuntime", {includes = "quickjs.h"}))
    end)
