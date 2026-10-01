import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
} from '@ohos/flutter_ohos';
import { onEventObject, onProfileSignIn, onProfileSignOff, init } from '@umeng/analytics';
import { deviceInfo } from '@kit.BasicServicesKit';

export default class UmengCommonSdkPlugin implements FlutterPlugin, MethodCallHandler {
  private channel: MethodChannel | null = null;
  private binding: FlutterPluginBinding | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return "UmengCommonSdkPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.binding = binding;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "umeng_common_sdk");
    this.channel.setMethodCallHandler(this)
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    this.channel = null;
    this.binding = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      case "getPlatformVersion":
        result.success(deviceInfo.osFullName);
        break;
      case "initCommon":
        this.handlePreInit(call, result);
        break;
      case "onProfileSignIn":
        this.handleOnProfileSignIn(call, result);
        break;
      case "onProfileSignOff":
        onProfileSignOff();
        break;
      case "onEvent":
        this.handleOnEvent(call, result);
        break;
      default:
        result.notImplemented();  // 必须加，否则 Dart 端 Future 永远 pending
        break;
    }
  }

  private handleOnEvent(call: MethodCall, result: MethodResult) {
    let args: Array<Object> = call.args as Array<Object>
    const eventId: string = args[0] as string;
    if (args.length > 1) {
      onEventObject(eventId, args[1] as Record<string, string | number>)
    } else {
      onEventObject(eventId)
    }
  }

  private handleOnProfileSignIn(call: MethodCall, result: MethodResult) {
    let args: Array<string> = call.args as Array<string>
    if (args.length < 2) {
      result.error("INVALID_ARGUMENT", "onProfileSignIn requires userID and provider", null);
      return
    }
    onProfileSignIn(args[0], args[1])
  }

  private handlePreInit(call: MethodCall, result: MethodResult): void {
    try {
      init();
    } catch (e) {
      result.error("PREINIT_ERROR", `preInit failed: ${e}`, null);
    }
  }
}