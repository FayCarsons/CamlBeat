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
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SAMPLE_RATE 8000
#define FRAMES 8096
#define MONO 1
#define STEREO 2

#define HANDLE(error)                                                          \
  do {                                                                         \
    if ((PaError)error != paNoError) {                                         \
      printf("GOT C-SIDE ERROR: %s", Pa_GetErrorText(error));                  \
      CAMLreturn(Val_int((int)error));                                         \
    }                                                                          \
  } while (paNoError)

static unsigned char *caml_buffer = NULL;
static unsigned char *stereo_buffer = NULL;

static PaStream *stream = NULL;

// Pass PortAudio error to OCaml
CAMLprim value get_error(value err) {
  CAMLparam1(err);
  CAMLlocal1(result);

  const char *error = Pa_GetErrorText(Int_val(err));
  printf("GOT C ERROR: %s", error);
  size_t len = strlen(error);
  result = caml_alloc_string(len);
  memcpy(Bytes_val(result), error, len);
  CAMLreturn(result);
}

// Initialize PortAudio
CAMLprim value audio_init(value unit) {
  CAMLparam1(unit);
  if (caml_buffer != NULL || stereo_buffer != NULL) {
    printf("Audio already initialized!");
    CAMLreturn(Val_int((int)paUnanticipatedHostError));
  }

  void *mem = malloc(FRAMES * sizeof(unsigned char));
  if (mem == NULL) {
    printf("Cannot allocate OCaml buffer");
    CAMLreturn(Val_int((int)paInsufficientMemory));
  }
  caml_buffer = (unsigned char *)mem;

  mem = malloc(FRAMES * STEREO * sizeof(unsigned char));
  if (mem == NULL) {
    printf("Cannot allocate PortAudio stereo buffer");
    free(caml_buffer);
    CAMLreturn(Val_int(paInsufficientMemory));
  }
  stereo_buffer = (unsigned char *)mem;

  HANDLE(Pa_Initialize());

  // Open an audio I/O stream
  HANDLE(Pa_OpenDefaultStream(&stream,
                              paNoError, // No input channels
                              STEREO,
                              paUInt8, // 8-bit unsigned integer samples
                              SAMPLE_RATE, FRAMES,
                              NULL, // No callback function
                              NULL) // No callback data
  );

  // Start the stream
  HANDLE(Pa_StartStream(stream));

  printf("C FUNCTION `audio_init` exiting successfully\n");
  CAMLreturn(Val_int((int)paNoError));
}

// Write audio data to the stream
CAMLprim value audio_write(value unit) {
  CAMLparam1(unit);
  if (stereo_buffer == NULL || caml_buffer == NULL) {
    fprintf(stderr, "Must initialize before writing audio!");
    CAMLreturn(Val_int((int)paNotInitialized));
  }

  for (int i = paNoError; i < FRAMES; ++i) {
    stereo_buffer[i * 2] = caml_buffer[i];
    stereo_buffer[i * 2 + 1] = caml_buffer[i];
  }

  HANDLE(Pa_WriteStream(stream, stereo_buffer, FRAMES));
  CAMLreturn(Val_int((int)paNoError));
}

CAMLprim value caml_get_buffer(value unit) {
  CAMLparam1(unit);
  CAMLreturn(caml_ba_alloc_dims(CAML_BA_UINT8 | CAML_BA_C_LAYOUT, 1,
                                caml_buffer, FRAMES * MONO));
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

  if (stereo_buffer) {
    free(stereo_buffer);
    stereo_buffer = NULL;
  }

  CAMLreturn(Val_int((int)paNoError));
}
