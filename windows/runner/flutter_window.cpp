#include "flutter_window.h"

#include <flutter/standard_method_codec.h>
#include <flutter_windows.h>

#include <optional>

#include "flutter/generated_plugin_registrant.h"

using flutter::EncodableMap;
using flutter::EncodableValue;

namespace {

int IntArg(const EncodableMap& args, const char* name) {
  return std::get<int32_t>(args.at(EncodableValue(name)));
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  window_channel_ = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      flutter_controller_->engine()->messenger(), "psito_player/window",
      &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const auto& call, auto result) {
        HandleWindowCall(call, std::move(result));
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::HandleWindowCall(
    const flutter::MethodCall<EncodableValue>& call,
    std::unique_ptr<flutter::MethodResult<EncodableValue>> result) {
  HWND window = GetHandle();
  if (call.method_name() == "present") {
    if (IsIconic(window)) {
      ShowWindow(window, SW_RESTORE);
    }
    SetForegroundWindow(window);
    result->Success();
  } else if (call.method_name() == "resize") {
    const auto& args = std::get<EncodableMap>(*call.arguments());
    // Maximizada, a janela ignora o pedido de tamanho
    if (IsZoomed(window)) {
      ShowWindow(window, SW_RESTORE);
    }
    // O Dart pede a área do conteúdo, em pixels lógicos
    const UINT dpi = FlutterDesktopGetDpiForHWND(window);
    RECT frame = {0, 0, MulDiv(IntArg(args, "width"), dpi, 96),
                  MulDiv(IntArg(args, "height"), dpi, 96)};
    AdjustWindowRectExForDpi(
        &frame, static_cast<DWORD>(GetWindowLongPtr(window, GWL_STYLE)), FALSE,
        static_cast<DWORD>(GetWindowLongPtr(window, GWL_EXSTYLE)), dpi);
    const bool above = std::get<bool>(args.at(EncodableValue("above")));
    SetWindowPos(window, above ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0,
                 frame.right - frame.left, frame.bottom - frame.top,
                 SWP_NOMOVE | SWP_NOACTIVATE);
    result->Success();
  } else {
    result->NotImplemented();
  }
}

void FlutterWindow::OnDestroy() {
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
