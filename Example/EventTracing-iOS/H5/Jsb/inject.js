var bridge = {
  default: this, // for typescript
  call: function (module, method, args, cb) {
    if (typeof args == "function") {
      cb = args;
      args = {};
    }
    args = args === undefined ? null : args;
    window.__et_message_call_seq++
    if (typeof cb == "function") {
      var cb_name = "__etcb_" + window.__et_message_call_seq;
      window[cb_name] = cb;
    }

    // For iOS WK: `et_js_is_wk` provided
    if (window.et_js_is_wk) {
      setTimeout(() => {
        window.webkit.messageHandlers.et_js_wk_bridge.postMessage({
          seq: window.__et_message_call_seq + "",
          module: module,
          method: method,
          params: args
        });
      }, 0);
    }
    // For Android
    // else if(window.__et_bridge_use_prompt){
    //    ret = prompt("__et_bridge=" + method, args);
    // }
  },
  registe: function (module, method, fun) {
    var q = window.__et_bridge_f;
    if (typeof fun != "function") {
      return
    }

    if (method === undefined || method == '' || method == null) {
      return
    }

    if (module === undefined || module == '' || module == null) {
      q[method] = fun
      return
    }

    var methods = q[module]
    methods = methods==undefined ? {} : methods
    methods[method] = fun
    q[module] = methods
  },
  isBridgeAvaiable: function (module, method, cb) {
    this.call('__et_jsb_internal_bridge', 'avaiable', {'module': module, 'method': method}, function(error, result, context){
      cb(result['avaiable'], {'module': module, 'method': method})
    })
  }
};

!(function () {
  if (window.__et_bridge_initialized) return;

  var ob = {
    __et_bridge_initialized: true,
    __et_bridge_f: {},
    __et_message_call_seq: 0,
    __et_bridge: bridge,
    __et_call_cb_from_native: function (seq, error, result, context) {
      var cb_name = "__etcb_" + seq;
      var cb = window[cb_name]
      if (typeof cb != 'function') {
        return
      }

      setTimeout(() => {
        cb(error, result, context)
      }, 0);
    },
    __et_call_f_from_native: function (module, method, args) {
        var methods = window.__et_bridge_f[module]
        var f = methods[method]
        if (typeof f != 'function') {
          return 
        }

        setTimeout(() => {
          f(args, {'module': module, 'method': method})
        }, 0);
    },
    __et_has_js_method: function (module, method) {
      var methods = window.__et_bridge_f[module]
      var f = methods[method]
      return f && (typeof f == 'function');
    }
  };
  for (var attr in ob) {
    window[attr] = ob[attr];
  }
})();
