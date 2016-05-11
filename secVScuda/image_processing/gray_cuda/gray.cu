#include <cv.h>
#include <cuda.h>
#include <highgui.h>

#define RED 2
#define GREEN 1
#define BLUE 0

using namespace cv;

__global__ void img2gray(unsigned char *input, int width, int height, unsigned char *output){
  
  int row = blockIdx.y*blockDim.y+threadIdx.y;
  int col = blockIdx.x*blockDim.x+threadIdx.x;
	
	if( (row < height) && (col < width) ){
	  int average = (input[(row*width+col)*3+RED] + input[(row*width+col)*3+GREEN] +input[(row*width+col)*3+BLUE])/3;
	  output[row*width+col] = average;
	}
	
}

int main( int argc, char** argv )
{
	char* imageName = argv[1];

	Mat image;
	image = imread( imageName, CV_LOAD_IMAGE_COLOR );
	

	if( argc != 2 || !image.data )
	{
		printf( " No image data \n " );
		return -1;
	}
	
	Size s = image.size();

  cudaError_t error = cudaSuccess;
  int width = s.width;
  int height = s.height;
  int size = sizeof(unsigned char)*width*height*image.channels();
  int osize = sizeof(unsigned char)*width*height;
  
  unsigned char *h_imageInput, *d_imageInput, *h_imageOutput, *d_imageOutput;
  
  h_imageInput = (unsigned char*)malloc(size);
  error = cudaMalloc((void**)&d_imageInput,size);
  
  if(error != cudaSuccess){
    printf("Error reservando memoria para d_imageInput\n");
    exit(-1);
  }

  
  h_imageOutput = (unsigned char*)malloc(osize);
  error = cudaMalloc((void**)&d_imageOutput,osize);
  
  if(error != cudaSuccess){
    printf("Error reservando memoria para d_imageOutput\n");
    exit(-1);
  }
  
  h_imageInput = image.data;
  
  error = cudaMemcpy(d_imageInput,h_imageInput,size, cudaMemcpyHostToDevice);
  if(error != cudaSuccess){
    printf("Error copiando al device para para d_imageInput\n");
    exit(-1);
  }
  
  int blockSize = 32;
  dim3 dimBlock(blockSize,blockSize,1);
  dim3 dimGrid(ceil(width/float(blockSize)),ceil(height/float(blockSize)),1);
  img2gray<<<dimGrid,dimBlock>>>(d_imageInput,width,height,d_imageOutput);
  cudaDeviceSynchronize();
  cudaMemcpy(h_imageOutput,d_imageOutput,osize,cudaMemcpyDeviceToHost);
  
  Mat gray_image;
  gray_image.create(height,width,CV_8UC1);
  gray_image.data = h_imageOutput;
  
  printf("Hijueputa vida\n");
  
  imshow("Color Image CUDA", image);  
  waitKey(0);
  imshow("Gray Image CUDA", gray_image);
  waitKey(0);
  
  cudaFree(d_imageInput);
  cudaFree(d_imageOutput);
  
	return 0;
}

