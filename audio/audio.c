#define CAML_NAME_SPACE

#include <caml/alloc.h>
#include <caml/bigarray.h>
#include <caml/callback.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

/* ---------------- */
#include <portaudio.h>

/* ---------------- */
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAMPLE_RATE 8000
#define BUFFER_SIZE 8096
#define MONO 1

#define HANDLE(error)                                                          \
  do {                                                                         \
    if ((PaError)error != paNoError) {                                         \
      CAMLreturn(Val_int((int)error));                                         \
    }                                                                          \
  } while (false)

static bool stream_started = false;

static uint8_t *caml_buffer = NULL;

static PaStream *stream = NULL;

// Pass PortAudio error to OCaml
CAMLprim value get_error(value err) {
  CAMLparam1(err);
  CAMLlocal1(result);

  const char *error = Pa_GetErrorText(Int_val(err));
  size_t len = strlen(error);
  result = caml_alloc_string(len);
  memcpy(Bytes_val(result), error, len);
  CAMLreturn(result);
}

// Initialize PortAudio
CAMLprim value audio_init(value unit) {
  CAMLparam1(unit);
  if (caml_buffer != NULL) {
    printf("Audio context already initialized");
    CAMLreturn(Val_int((int)paUnanticipatedHostError));
  }

  void *buf = malloc(BUFFER_SIZE * sizeof(uint8_t));
  if (buf == NULL) {
    printf("Cannot allocate OCaml buffer");
    CAMLreturn(Val_int((int)paInsufficientMemory));
  }
  caml_buffer = (uint8_t *)buf;
  memset(caml_buffer, 0, BUFFER_SIZE * sizeof(uint8_t));

  HANDLE(Pa_Initialize());

  PaDeviceIndex device = Pa_GetDefaultOutputDevice();
  if (device == paNoDevice) {
    CAMLreturn(Val_int((int)paNoDevice));
  }

  PaStreamParameters output_params = {
      .device = device,
      .channelCount = 1,
      .sampleFormat = paUInt8,
      .suggestedLatency = Pa_GetDeviceInfo(device)->defaultLowOutputLatency,
      .hostApiSpecificStreamInfo = NULL,
  };

  // Open an audio I/O stream
  HANDLE(Pa_OpenStream(&stream,
                       NULL, // No input
                       &output_params, SAMPLE_RATE, BUFFER_SIZE, paClipOff,
                       NULL, // No callback, we're using blocking I/O
                       NULL));

  CAMLreturn(Val_int((int)paNoError));
}

// Write audio data to the stream
CAMLprim value audio_write(value unit) {
  CAMLparam1(unit);

  if (!stream_started) {
    // Start the stream
    HANDLE(Pa_StartStream(stream));
    stream_started = true;
  }

  if (caml_buffer == NULL) {
    printf("Must initialize before writing audio!");
    CAMLreturn(Val_int((int)paNotInitialized));
  }

  HANDLE(Pa_WriteStream(stream, caml_buffer, BUFFER_SIZE));
  CAMLreturn(Val_int((int)paNoError));
}

CAMLprim value caml_get_buffer_size(value unit) {
  CAMLparam1(unit);
  CAMLreturn(Val_int(BUFFER_SIZE));
}

CAMLprim value caml_get_buffer(value unit) {
  CAMLparam1(unit);
  CAMLreturn(caml_ba_alloc_dims(CAML_BA_UINT8 | CAML_BA_C_LAYOUT, 1,
                                caml_buffer, BUFFER_SIZE));
}

CAMLprim value audio_cleanup(value unit) {
  CAMLparam1(unit);
  if (stream) {
    HANDLE(Pa_StopStream(stream));
    HANDLE(Pa_CloseStream(stream));
  }
  Pa_Terminate();

  if (caml_buffer) {
    free(caml_buffer);
    caml_buffer = NULL;
  }

  CAMLreturn(Val_int((int)paNoError));
}
